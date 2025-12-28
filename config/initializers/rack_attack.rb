# Rate limiting configuration for Chợ Việt
class Rack::Attack
  # Cache store for tracking requests (uses Rails.cache by default)
  Rack::Attack.cache.store = Rails.cache

  # Safelist development and test environments
  safelist('allow-localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end if Rails.env.development? || Rails.env.test?

  # Track logged in users by user ID, anonymous by IP
  def self.track_identifier(req)
    if req.env['warden'].user&.id
      "user:#{req.env['warden'].user.id}"
    else
      "ip:#{req.ip}"
    end
  end

  ## Throttle Configurations

  # 1. General API/Request throttle
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets', '/packs')
  end

  # 2. Login attempts
  throttle('logins/email', limit: 5, period: 20.minutes) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.params.dig('user', 'email')&.downcase&.strip
    end
  end

  # 3. Sign up attempts
  throttle('signups/ip', limit: 3, period: 1.hour) do |req|
    if req.path == '/users' && req.post?
      req.ip
    end
  end

  # 4. Message sending (DM)
  throttle('messages/user', limit: 30, period: 1.minute) do |req|
    if req.path =~ %r{/conversation_messages} && req.post?
      track_identifier(req)
    end
  end

  # 5. Post creation
  throttle('posts/user', limit: 10, period: 1.hour) do |req|
    if req.path == '/posts' && req.post?
      track_identifier(req)
    end
  end

  # 6. Report submission
  throttle('reports/user', limit: 5, period: 1.hour) do |req|
    if req.path =~ %r{/reports} && req.post?
      track_identifier(req)
    end
  end

  # 7. Block/Unblock actions
  throttle('blocks/user', limit: 10, period: 1.hour) do |req|
    if req.path =~ %r{/blocks} && (req.post? || req.delete?)
      track_identifier(req)
    end
  end

  # 8. Aggressive scraping protection
  throttle('aggressive/ip', limit: 1000, period: 1.hour) do |req|
    req.ip unless req.path.start_with?('/assets', '/packs')
  end

  ## Custom Responses

  # Response for throttled requests
  self.throttled_responder = lambda do |env|
    match_data = env['rack.attack.match_data']
    now = match_data[:epoch_time]
    headers = {
      'Content-Type' => 'application/json',
      'X-RateLimit-Limit' => match_data[:limit].to_s,
      'X-RateLimit-Remaining' => '0',
      'X-RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
    }
    
    # Check if request expects JSON
    if env['HTTP_ACCEPT']&.include?('application/json')
      [429, headers, [{
        error: "Too many requests",
        message: "Rate limit exceeded. Please try again later.",
        retry_after: headers['X-RateLimit-Reset']
      }.to_json]]
    else
      # HTML response for browser requests
      [429, headers.merge('Content-Type' => 'text/html'), [<<~HTML]]
        <!DOCTYPE html>
        <html>
        <head>
          <title>Too Many Requests - Chợ Việt</title>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <style>
            body { 
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              display: flex; 
              align-items: center; 
              justify-content: center; 
              min-height: 100vh; 
              margin: 0;
              background-color: #f3f4f6;
            }
            .container { 
              text-align: center; 
              padding: 2rem;
              background: white;
              border-radius: 0.5rem;
              box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
              max-width: 32rem;
              margin: 1rem;
            }
            h1 { 
              color: #dc2626; 
              font-size: 3rem;
              margin: 0 0 1rem 0;
            }
            h2 { 
              color: #374151;
              font-size: 1.5rem;
              font-weight: 600;
              margin: 0 0 1rem 0;
            }
            p { 
              color: #6b7280; 
              margin: 0 0 1.5rem 0;
              line-height: 1.5;
            }
            a { 
              color: #3b82f6; 
              text-decoration: none;
              font-weight: 500;
            }
            a:hover { 
              text-decoration: underline; 
            }
            .countdown {
              font-size: 1.25rem;
              color: #dc2626;
              font-weight: 600;
              margin: 1.5rem 0;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>429</h1>
            <h2>Quá nhiều yêu cầu / 너무 많은 요청</h2>
            <p>
              Bạn đã gửi quá nhiều yêu cầu. Vui lòng thử lại sau.<br>
              너무 많은 요청을 보내셨습니다. 잠시 후 다시 시도해주세요.
            </p>
            <div class="countdown" id="countdown"></div>
            <a href="/">Về trang chủ / 홈으로</a>
          </div>
          <script>
            const resetTime = #{headers['X-RateLimit-Reset']} * 1000;
            const countdownEl = document.getElementById('countdown');
            
            function updateCountdown() {
              const now = Date.now();
              const diff = Math.max(0, resetTime - now);
              const seconds = Math.ceil(diff / 1000);
              
              if (seconds > 0) {
                countdownEl.textContent = `${seconds}s`;
                setTimeout(updateCountdown, 1000);
              } else {
                window.location.reload();
              }
            }
            
            updateCountdown();
          </script>
        </body>
        </html>
      HTML
    end
  end

  ## Logging (optional)
  ActiveSupport::Notifications.subscribe("rack.attack") do |name, start, finish, request_id, payload|
    req = payload[:request]
    Rails.logger.info "[Rack::Attack] Throttled #{req.ip} - #{req.path}"
  end
end
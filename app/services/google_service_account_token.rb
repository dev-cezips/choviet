require "jwt"
require "net/http"
require "json"

class GoogleServiceAccountToken
  TOKEN_URI = "https://oauth2.googleapis.com/token"
  SCOPE = "https://www.googleapis.com/auth/firebase.messaging"

  def self.fetch
    # Simple cache (1 hour)
    cached = Rails.cache.read("google_sa_access_token")
    return cached if cached.present?

    sa_json = JSON.parse(ENV.fetch("FCM_SERVICE_ACCOUNT_JSON"))
    now = Time.now.to_i

    jwt_payload = {
      iss: sa_json.fetch("client_email"),
      scope: SCOPE,
      aud: TOKEN_URI,
      iat: now,
      exp: now + 3600
    }

    key = OpenSSL::PKey::RSA.new(sa_json.fetch("private_key"))
    jwt = JWT.encode(jwt_payload, key, "RS256")

    uri = URI(TOKEN_URI)
    req = Net::HTTP::Post.new(uri)
    req.set_form_data(
      "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
      "assertion" => jwt
    )

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
    unless res.is_a?(Net::HTTPSuccess)
      Rails.logger.error "[GoogleAuth] Error: #{res.code} #{res.body}"
      raise "OAuth token error: #{res.code} #{res.body}"
    end

    body = JSON.parse(res.body)
    token = body.fetch("access_token")
    expires_in = body.fetch("expires_in", 3600) - 300 # 5 minutes buffer
    
    Rails.cache.write("google_sa_access_token", token, expires_in: expires_in.seconds)
    token
  rescue => e
    Rails.logger.error "[GoogleAuth] Failed to fetch token: #{e.message}"
    raise
  end
end
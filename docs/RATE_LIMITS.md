# Rate Limiting Configuration

## Overview

Chợ Việt uses Rack::Attack to implement rate limiting and protect against abuse. The configuration can be found in `config/initializers/rack_attack.rb`.

## Rate Limits

### General Requests
- **Limit**: 300 requests per 5 minutes per IP
- **Applies to**: All requests except assets
- **Purpose**: Prevent general abuse and scraping

### Authentication
- **Login**: 5 attempts per 20 minutes per email
- **Sign up**: 3 registrations per hour per IP
- **Purpose**: Prevent brute force attacks and spam accounts

### User Actions
- **Messages**: 30 messages per minute per user
- **Posts**: 10 posts per hour per user
- **Reports**: 5 reports per hour per user
- **Blocks**: 10 block/unblock actions per hour per user

### Aggressive Protection
- **Limit**: 1000 requests per hour per IP
- **Purpose**: Block aggressive scrapers and bots

## Response Headers

When rate limited, the following headers are returned:
- `X-RateLimit-Limit`: The rate limit ceiling for the request
- `X-RateLimit-Remaining`: Number of requests remaining
- `X-RateLimit-Reset`: Timestamp when the rate limit will reset

## Customization

### Adjusting Limits

Edit `config/initializers/rack_attack.rb`:

```ruby
throttle('messages/user', limit: 30, period: 1.minute) do |req|
  # Change limit or period as needed
end
```

### Adding New Throttles

```ruby
throttle('custom/action', limit: 10, period: 1.hour) do |req|
  if req.path == '/custom/path' && req.post?
    track_identifier(req)
  end
end
```

### Whitelisting

Add IP addresses or conditions to the safelist:

```ruby
safelist('allow-admin') do |req|
  req.ip == 'trusted.ip.address'
end
```

## Monitoring

- Failed requests are logged to `Rails.logger`
- Monitor for 429 status codes in your APM
- Check Redis/cache for throttle data:
  ```ruby
  Rails.cache.read("rack::attack:throttle:messages/user:user:123")
  ```

## Testing

Test rate limits in development:

```bash
# Test login rate limit
for i in {1..6}; do
  curl -X POST http://localhost:3000/users/sign_in \
    -d "user[email]=test@example.com&user[password]=wrong"
done

# Test message rate limit (requires auth token)
for i in {1..31}; do
  curl -X POST http://localhost:3000/conversations/1/conversation_messages \
    -H "Cookie: _session_id=..." \
    -d "conversation_message[body]=Test $i"
done
```

## User Experience

- HTML requests receive a friendly error page with countdown
- JSON requests receive structured error response
- Warning notices appear when users approach limits (80% threshold)
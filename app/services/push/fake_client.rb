module Push
  class FakeClient < Client
    def deliver!(endpoint:, title:, body:, data: {})
      Rails.logger.info "[PUSH:FAKE] Delivering to #{endpoint.platform} endpoint ##{endpoint.id}"
      Rails.logger.info "[PUSH:FAKE] User: #{endpoint.user.email}"
      Rails.logger.info "[PUSH:FAKE] Title: #{title}"
      Rails.logger.info "[PUSH:FAKE] Body: #{body}"
      Rails.logger.info "[PUSH:FAKE] Data: #{data.inspect}"
      Rails.logger.info "[PUSH:FAKE] Token: #{endpoint.token[0..20]}..." if endpoint.token

      # Simulate random failures in development for testing
      if Rails.env.development? && rand < 0.1
        raise "Simulated push delivery failure"
      end

      # Track in Rails cache for testing
      if Rails.env.test?
        Rails.cache.write(
          "push:fake:#{endpoint.id}",
          { title: title, body: body, data: data, delivered_at: Time.current },
          expires_in: 1.hour
        )
      end

      true
    end
  end
end

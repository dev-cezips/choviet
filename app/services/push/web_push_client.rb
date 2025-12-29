module Push
  class WebPushClient < Client
    def initialize
      @vapid_key = Rails.application.credentials.dig(:push, :vapid, :private_key)
      @vapid_public_key = Rails.application.credentials.dig(:push, :vapid, :public_key)
      @vapid_subject = Rails.application.credentials.dig(:push, :vapid, :subject) || "mailto:support@choviet.com"
    end
    
    def deliver!(endpoint:, title:, body:, data: {})
      return false unless endpoint.web?
      return false unless valid_config?
      
      require 'webpush' # Gem will be added later
      
      message = {
        title: title,
        body: body,
        icon: "/icon-192.png",
        badge: "/icon-72.png",
        data: data.merge(
          url: data[:url] || Rails.application.routes.url_helpers.root_url
        )
      }
      
      Webpush.payload_send(
        message: JSON.generate(message),
        endpoint: endpoint.endpoint_url,
        p256dh: endpoint.web_push_keys[:p256dh],
        auth: endpoint.web_push_keys[:auth],
        vapid: {
          private_key: @vapid_key,
          public_key: @vapid_public_key,
          subject: @vapid_subject
        }
      )
      
      endpoint.touch_last_seen!
      true
    rescue => e
      Rails.logger.error "[PUSH:WEB] Failed: #{e.message}"
      raise
    end
    
    private
    
    def valid_config?
      @vapid_key.present? && @vapid_public_key.present?
    end
  end
end
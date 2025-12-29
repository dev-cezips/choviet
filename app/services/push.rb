module Push
  class << self
    def client
      @client ||= build_client
    end
    
    def reset_client!
      @client = nil
    end
    
    private
    
    def build_client
      return FakeClient.new if Rails.env.test?
      return FakeClient.new if ENV["PUSH_FAKE"] == "1"
      
      # Use FCM if configured (priority for native apps)
      if fcm_configured?
        FcmClient.new
      elsif web_push_configured?
        WebPushClient.new
      else
        Rails.logger.info "[PUSH] No push service configured, using FakeClient"
        FakeClient.new
      end
    end
    
    def fcm_configured?
      ENV["FCM_PROJECT_ID"].present? && ENV["FCM_SERVICE_ACCOUNT_JSON"].present?
    end
    
    def web_push_configured?
      Rails.application.credentials.dig(:push, :vapid, :private_key).present?
    rescue
      false
    end
  end
end
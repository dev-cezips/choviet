module Trackable
  extend ActiveSupport::Concern

  def track_event(event_type, properties = {})
    # Skip tracking in development/test unless explicitly enabled
    return if Rails.env.test? && !ENV["ENABLE_ANALYTICS_IN_TEST"]

    AnalyticsEventJob.perform_later(
      user_id: current_user&.id,
      event_type: event_type,
      properties: properties,
      request_details: {
        ip: request.remote_ip,
        ua: request.user_agent,
        device: detect_device,
        locale: I18n.locale.to_s,
        referer: request.referer
      }
    )
  rescue => e
    Rails.logger.error "Analytics tracking failed: #{e.message}"
  end

  private

  def detect_device
    ua = request.user_agent.to_s.downcase

    case ua
    when /iphone|ipod/
      "ios"
    when /ipad/
      "ipad"
    when /android/
      "android"
    when /mobile/
      "mobile"
    when /tablet/
      "tablet"
    else
      "desktop"
    end
  end
end

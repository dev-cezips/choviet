class AnalyticsEventJob < ApplicationJob
  queue_as :analytics

  retry_on ActiveRecord::RecordInvalid, wait: 5.seconds, attempts: 3

  def perform(user_id:, event_type:, properties:, request_details:)
    AnalyticsEvent.create!(
      user_id: user_id,
      event_type: event_type,
      properties: properties,
      request_details: request_details
    )
  rescue => e
    Rails.logger.error "AnalyticsEventJob failed: #{e.message}"
    raise
  end
end
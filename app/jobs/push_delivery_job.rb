class PushDeliveryJob < ApplicationJob
  queue_as :default
  
  # Custom error for permanent failures that should not retry
  class PermanentDeliveryError < StandardError; end
  
  # Retry with exponential backoff for transient failures only
  retry_on StandardError, wait: :exponentially_longer, attempts: 3 do |job, error|
    # If it's a permanent error, don't retry
    if job.send(:permanent_error?, error)
      raise PermanentDeliveryError, error.message
    end
  end
  
  # Don't retry permanent errors
  discard_on PermanentDeliveryError
  
  def perform(notification_id)
    notification = Notification.find(notification_id)
    return if notification.delivered? || notification.skipped?
    
    # Check if should deliver (settings, blocks, etc)
    unless notification.should_deliver?
      reason = determine_skip_reason(notification)
      return notification.mark_skipped!(reason)
    end
    
    # Get active endpoints
    endpoints = notification.recipient.push_endpoints.active
    if endpoints.empty?
      return notification.mark_skipped!("no_active_endpoints")
    end
    
    # Prepare push content
    title = notification.localized_title
    body = notification.localized_body
    data = prepare_push_data(notification)
    
    # Deliver to all endpoints
    delivered_count = 0
    failed_count = 0
    
    endpoints.each do |endpoint|
      begin
        Push.client.deliver!(
          endpoint: endpoint,
          title: title,
          body: body,
          data: data
        )
        
        delivered_count += 1
        endpoint.touch_last_seen!
      rescue => e
        failed_count += 1
        Rails.logger.error "[PushDeliveryJob] Failed to deliver to endpoint #{endpoint.id}: #{e.message}"
        
        # Deactivate endpoint after multiple failures
        if endpoint_should_deactivate?(endpoint, e)
          endpoint.update!(active: false)
        end
      end
    end
    
    # Update notification status
    if delivered_count > 0
      notification.mark_delivered!
    elsif failed_count > 0
      notification.mark_failed!("All endpoints failed")
    else
      notification.mark_skipped!("No endpoints processed")
    end
  end
  
  private
  
  def determine_skip_reason(notification)
    recipient = notification.recipient
    
    return "push_disabled" unless recipient.notification_push_enabled?
    return "dm_disabled" unless recipient.notification_dm_enabled? if notification.dm_message?
    return "blocked" if notification.actor && Block.blocked?(recipient, notification.actor)
    
    "unknown"
  end
  
  def prepare_push_data(notification)
    data = notification.data || {}
    
    case notification.kind
    when "dm_message"
      data.merge(
        type: "dm_message",
        conversation_id: notification.notifiable.conversation_id,
        url: Rails.application.routes.url_helpers.conversation_url(
          notification.notifiable.conversation,
          host: ENV.fetch('DEFAULT_URL_HOST', 'localhost:3000')
        )
      )
    else
      data
    end
  end
  
  def endpoint_should_deactivate?(endpoint, error)
    permanent_error?(error)
  end
  
  def permanent_error?(error)
    # These are permanent errors that indicate invalid tokens
    error.message.include?("InvalidRegistration") ||
    error.message.include?("NotRegistered") ||
    error.message.include?("BadDeviceToken") ||
    error.message.include?("UNREGISTERED") ||
    error.message.include?("INVALID_ARGUMENT") ||
    error.message.include?("registration-token-not-registered")
  end
end
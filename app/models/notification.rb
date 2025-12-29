class Notification < ApplicationRecord
  belongs_to :recipient, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :notifiable, polymorphic: true, optional: true

  enum :kind, {
    dm_message: 0,        # Direct message received
    post_liked: 1,        # Someone liked your post (future)
    post_commented: 2,    # Someone commented on your post (future)
    review_received: 3,   # Someone left you a review (future)
    system_alert: 4       # System notifications (future)
  }

  enum :status, {
    pending: 0,     # Not yet processed
    delivered: 1,   # Successfully sent
    skipped: 2,     # Skipped due to settings/blocks
    failed: 3       # Delivery failed
  }

  validates :kind, presence: true
  validates :recipient, presence: true

  scope :undelivered, -> { where(status: :pending) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(recipient: user) }
  scope :unread, -> { where(read_at: nil) } # For future in-app notifications

  # Localized content helpers
  def localized_title
    case kind
    when "dm_message"
      if recipient.vietnamese?
        "Tin nhắn mới từ #{actor.display_name}"
      else
        "#{actor.display_name}님의 새 메시지"
      end
    else
      title
    end
  end

  def localized_body
    case kind
    when "dm_message"
      body.truncate(80)
    else
      body
    end
  end

  # Check if should be delivered
  def should_deliver?
    return false unless recipient.notification_push_enabled?
    return false unless recipient.notification_dm_enabled? if dm_message?
    return false if actor && Block.blocked?(recipient, actor)
    true
  end

  # Mark as delivered
  def mark_delivered!
    update!(status: :delivered, delivered_at: Time.current)
  end

  # Mark as skipped with reason
  def mark_skipped!(reason)
    update!(status: :skipped, failure_reason: reason)
  end

  # Mark as failed with error
  def mark_failed!(error_message)
    update!(status: :failed, failure_reason: error_message)
  end
end

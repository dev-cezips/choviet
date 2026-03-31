class Like < ApplicationRecord
  belongs_to :user
  belongs_to :post
  validates :user_id, uniqueness: { scope: :post_id }

  after_create_commit :enqueue_like_notification

  private

  def enqueue_like_notification
    # Don't notify if user liked their own post
    return if user_id == post.user_id

    recipient = post.user
    return unless recipient

    # Skip if users have blocked each other
    return if Block.blocked?(user, recipient)

    # Spam prevention: 1 push per post per user per hour
    cache_key = "push:like:#{post_id}:#{user_id}"
    written = Rails.cache.write(cache_key, true, expires_in: 1.hour, unless_exist: true)

    unless written
      Rails.logger.info "[Like] Skipping notification due to rate limit"
      return
    end

    # Create notification record
    notification = Notification.create!(
      recipient: recipient,
      actor: user,
      notifiable: self,
      kind: :post_liked,
      title: user.display_name,
      body: post.title.truncate(50),
      data: {
        post_id: post_id,
        like_id: id,
        liker_name: user.display_name
      }
    )

    # Enqueue push delivery
    PushDeliveryJob.perform_later(notification.id)
  rescue => e
    Rails.logger.error "[Like] Failed to create notification: #{e.message}"
  end
end

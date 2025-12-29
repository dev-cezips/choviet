class ConversationMessage < ApplicationRecord
  include Reportable

  belongs_to :conversation
  belongs_to :user

  validates :body, presence: true

  # Broadcast to conversation channel after creation (skip in test environment)
  after_create_commit :broadcast_message, unless: -> { Rails.env.test? }

  # Send push notification to recipient
  after_create_commit :enqueue_dm_notification

  # For rendering purposes
  def mine?(current_user)
    user == current_user
  end

  # Get the other user in the conversation (for display purposes)
  def recipient
    conversation.other_user(user)
  end

  private

  def broadcast_message
    # Broadcast to each participant with their own view
    conversation.participants.each do |participant|
      broadcast_append_to [ conversation, participant ],
        partial: "conversation_messages/message",
        locals: { message: self, current_user: participant },
        target: "messages"
    end
  end

  def enqueue_dm_notification
    # Get the other participant
    other_user = conversation.other_user(user)
    return unless other_user

    # Skip if users have blocked each other
    return if Block.blocked?(user, other_user)

    # Spam prevention: 1 push per conversation per 10 seconds
    cache_key = "push:dm:#{conversation.id}:#{other_user.id}"

    # Atomic: only writes if key does NOT exist
    written = Rails.cache.write(cache_key, true, expires_in: 10.seconds, unless_exist: true)

    unless written
      Rails.logger.info "[ConversationMessage] Skipping notification due to rate limit"
      return
    end

    # Create notification record
    notification = Notification.create!(
      recipient: other_user,
      actor: user,
      notifiable: self,
      kind: :dm_message,
      title: "New message from #{user.display_name}",
      body: body.truncate(80),
      data: {
        conversation_id: conversation.id,
        message_id: id,
        sender_name: user.display_name
      }
    )

    # Enqueue push delivery
    PushDeliveryJob.perform_later(notification.id)
  rescue => e
    Rails.logger.error "[ConversationMessage] Failed to create notification: #{e.message}"
    # Don't fail the message creation if notification fails
  end
end

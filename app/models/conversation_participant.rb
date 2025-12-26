class ConversationParticipant < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  
  validates :user_id, uniqueness: { scope: :conversation_id }
  
  def mark_as_read!
    update!(last_read_at: Time.current)
  end
  
  def has_unread_messages?
    return true if last_read_at.nil?
    
    conversation.conversation_messages
      .where("created_at > ?", last_read_at)
      .where.not(user_id: user_id)
      .exists?
  end
end
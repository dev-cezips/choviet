class ConversationMessage < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  
  validates :body, presence: true
  
  # Broadcast to conversation channel after creation
  after_create_commit -> {
    broadcast_append_to conversation,
      partial: "conversation_messages/message",
      locals: { message: self },
      target: "messages"
  }
  
  # For rendering purposes
  def mine?(current_user)
    user == current_user
  end
  
  # Get the other user in the conversation (for display purposes)
  def recipient
    conversation.other_user(user)
  end
end
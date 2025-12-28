class ConversationMessage < ApplicationRecord
  belongs_to :conversation
  belongs_to :user
  has_many :reports, as: :reportable, dependent: :destroy
  
  validates :body, presence: true
  
  # Broadcast to conversation channel after creation (skip in test environment)
  after_create_commit :broadcast_message, unless: -> { Rails.env.test? }
  
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
      broadcast_append_to [conversation, participant],
        partial: "conversation_messages/message",
        locals: { message: self, current_user: participant },
        target: "messages"
    end
  end
end
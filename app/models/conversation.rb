class Conversation < ApplicationRecord
  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :conversation_messages, dependent: :destroy
  
  # Ensure user_a_id is always smaller than user_b_id
  before_validation :normalize_user_ids, if: -> { kind == "direct" }
  
  def self.find_or_create_direct(user1, user2)
    return nil if user1 == user2 # Can't chat with yourself
    
    a, b = [user1.id, user2.id].minmax
    
    convo = find_or_create_by!(kind: "direct", user_a_id: a, user_b_id: b)
    convo.conversation_participants.find_or_create_by!(user: user1)
    convo.conversation_participants.find_or_create_by!(user: user2)
    convo
  end
  
  def includes_user?(user)
    return false unless user
    user.id == user_a_id || user.id == user_b_id
  end
  
  def other_user(current_user)
    return nil unless includes_user?(current_user)
    
    if current_user.id == user_a_id
      User.find(user_b_id)
    else
      User.find(user_a_id)
    end
  end
  
  def unread_count_for(user)
    cp = conversation_participants.find_by(user: user)
    return 0 unless cp&.last_read_at
    
    conversation_messages
      .where("created_at > ?", cp.last_read_at)
      .where.not(user_id: user.id)
      .count
  end
  
  def last_message
    conversation_messages.order(created_at: :desc).first
  end
  
  private
  
  def normalize_user_ids
    return unless user_a_id && user_b_id
    
    if user_a_id > user_b_id
      self.user_a_id, self.user_b_id = user_b_id, user_a_id
    end
  end
end
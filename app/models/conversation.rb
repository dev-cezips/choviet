class Conversation < ApplicationRecord
  belongs_to :user_a, class_name: "User", foreign_key: :user_a_id
  belongs_to :user_b, class_name: "User", foreign_key: :user_b_id

  has_many :conversation_participants, dependent: :destroy
  has_many :participants, through: :conversation_participants, source: :user
  has_many :conversation_messages, dependent: :destroy

  # Ensure user_a_id is always smaller than user_b_id
  before_validation :normalize_user_ids, if: -> { kind == "direct" }

  # Scopes
  scope :not_blocked_for, ->(user) {
    joins("LEFT JOIN blocks b1 ON b1.blocker_id = #{user.id} AND (b1.blocked_id = conversations.user_a_id OR b1.blocked_id = conversations.user_b_id)")
      .joins("LEFT JOIN blocks b2 ON b2.blocked_id = #{user.id} AND (b2.blocker_id = conversations.user_a_id OR b2.blocker_id = conversations.user_b_id)")
      .where("b1.id IS NULL AND b2.id IS NULL")
  }

  def self.find_or_create_direct(user1, user2)
    return nil if user1 == user2 # Can't chat with yourself

    a, b = [ user1.id, user2.id ].minmax

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
    return 0 unless cp

    # If last_read_at is nil, all messages from others are unread
    if cp.last_read_at.nil?
      conversation_messages.where.not(user_id: user.id).count
    else
      conversation_messages
        .where("created_at > ?", cp.last_read_at)
        .where.not(user_id: user.id)
        .count
    end
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

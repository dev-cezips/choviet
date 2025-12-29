class Block < ApplicationRecord
  belongs_to :blocker, class_name: "User"
  belongs_to :blocked, class_name: "User"

  validates :blocker_id, uniqueness: { scope: :blocked_id }
  validate :cannot_block_self

  # Scopes for bidirectional blocking
  scope :between, ->(user1, user2) {
    where(
      "(blocker_id = ? AND blocked_id = ?) OR (blocker_id = ? AND blocked_id = ?)",
      user1.id, user2.id, user2.id, user1.id
    )
  }

  # Check if users have blocked each other (in either direction)
  def self.blocked?(user1, user2)
    between(user1, user2).exists?
  end

  private

  def cannot_block_self
    errors.add(:blocked_id, "can't block yourself") if blocker_id == blocked_id
  end
end

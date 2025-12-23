class CommunityMembership < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :community

  # Enums
  enum :role, {
    member: 0,
    moderator: 1,
    admin: 2
  }

  # Validations
  validates :user_id, uniqueness: { scope: :community_id, message: "is already a member of this community" }
  validates :role, presence: true
  validates :joined_at, presence: true

  # Scopes
  scope :admins, -> { where(role: "admin") }
  scope :moderators, -> { where(role: [ "admin", "moderator" ]) }
  scope :recent, -> { order(joined_at: :desc) }

  # Callbacks
  before_validation :set_joined_at, on: :create

  # Instance methods
  def can_moderate?
    admin? || moderator?
  end

  def can_manage_members?
    admin?
  end

  private

  def set_joined_at
    self.joined_at ||= Time.current
  end
end

class Community < ApplicationRecord
  # Associations
  has_many :community_memberships, dependent: :destroy
  has_many :members, through: :community_memberships, source: :user
  has_many :posts

  # Validations
  validates :name, presence: true, length: { minimum: 3, maximum: 50 }
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9\-]+\z/, message: "only lowercase letters, numbers, and hyphens" }
  validates :location_code, presence: true

  # Scopes
  scope :public_communities, -> { where(is_private: false) }
  scope :by_location, ->(location_code) { where(location_code: location_code) }
  scope :popular, -> { order(member_count: :desc) }

  # Callbacks
  before_validation :generate_slug, on: :create
  after_create :create_default_settings

  # Instance methods
  def add_member(user, role = "member")
    community_memberships.create(user: user, role: role, joined_at: Time.current)
    increment!(:member_count)
  end

  def remove_member(user)
    membership = community_memberships.find_by(user: user)
    if membership&.destroy
      decrement!(:member_count)
    end
  end

  def member?(user)
    members.include?(user)
  end

  def admin?(user)
    community_memberships.find_by(user: user, role: "admin").present?
  end

  def to_param
    slug
  end

  private

  def generate_slug
    if slug.blank? && name.present?
      self.slug = name.parameterize
      # Ensure uniqueness
      counter = 1
      while Community.exists?(slug: slug)
        self.slug = "#{name.parameterize}-#{counter}"
        counter += 1
      end
    end
  end

  def create_default_settings
    self.settings ||= {
      post_approval_required: false,
      new_member_approval: is_private?,
      language_preferences: [ "vi", "ko" ],
      posting_rules: []
    }
    save
  end
end

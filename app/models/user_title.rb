class UserTitle < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :title

  # Validations
  validates :user_id, uniqueness: { scope: :title_id }
  validates :granted_at, presence: true

  # Callbacks
  before_validation :set_granted_at, on: :create

  # Scopes
  scope :primary_titles, -> { where(primary: true) }
  scope :recent, -> { order(granted_at: :desc) }
  scope :by_category, ->(category) { joins(:title).where(titles: { category: category }) }

  private

  def set_granted_at
    self.granted_at ||= Time.current
  end
end

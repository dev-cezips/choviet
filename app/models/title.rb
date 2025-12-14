class Title < ApplicationRecord
  # Constants
  CATEGORIES = %w[behavior seller community level].freeze
  
  # Associations
  has_many :user_titles, dependent: :destroy
  has_many :users, through: :user_titles
  
  # Validations
  validates :name_vi, presence: true
  validates :key, presence: true, uniqueness: true
  validates :category, inclusion: { in: CATEGORIES }
  validates :level_required, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  # Scopes
  scope :by_category, ->(category) { where(category: category) }
  scope :for_level, ->(level) { where('level_required <= ? OR level_required IS NULL', level) }
  scope :behavior_titles, -> { by_category('behavior') }
  scope :seller_titles, -> { by_category('seller') }
  scope :community_titles, -> { by_category('community') }
  scope :level_titles, -> { by_category('level') }
  
  # Class methods
  def self.find_by_key(key)
    find_by(key: key.to_s)
  end
  
  # Instance methods
  def behavior?
    category == 'behavior'
  end
  
  def seller?
    category == 'seller'
  end
  
  def community?
    category == 'community'
  end
  
  def level_based?
    category == 'level'
  end
  
  def display_icon
    icon.presence || '🏅'
  end
  
  def display_color
    color.presence || 'gray'
  end
end
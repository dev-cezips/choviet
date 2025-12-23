class Location < ApplicationRecord
  # Self-referential association
  belongs_to :parent, class_name: "Location", optional: true
  has_many :children, class_name: "Location", foreign_key: "parent_id"

  # Associations
  has_many :users
  has_many :posts
  has_many :communities

  # Validations
  validates :code, presence: true, uniqueness: true
  validates :name_ko, presence: true
  validates :name_vi, presence: true

  # Scopes
  scope :cities, -> { where(level: 1) }
  scope :districts, -> { where(level: 2) }
  scope :neighborhoods, -> { where(level: 3) }

  # Class methods for common locations
  def self.seoul
    find_by(code: "seoul")
  end

  def self.ansan
    find_by(code: "ansan")
  end

  # Instance methods
  def name(locale = I18n.locale)
    case locale.to_s
    when "ko"
      name_ko
    when "vi"
      name_vi
    else
      name_vi
    end
  end

  def city?
    level == 1
  end

  def district?
    level == 2
  end

  def neighborhood?
    level == 3
  end
end

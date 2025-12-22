class Category < ApplicationRecord
  # Self-referential association
  belongs_to :parent, class_name: "Category", optional: true
  has_many :subcategories, class_name: "Category", foreign_key: "parent_id", dependent: :destroy

  # Associations
  has_many :posts

  # Scopes
  scope :active, -> { where(active: true) }
  scope :root_categories, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :name_vi) }

  # Validations
  validates :name_vi, presence: true
  validates :name_ko, presence: true
  validates :position, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

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

  def full_path
    ancestors = []
    current = self
    while current
      ancestors.unshift(current)
      current = current.parent
    end
    ancestors
  end

  def root?
    parent_id.nil?
  end

  def leaf?
    subcategories.empty?
  end
end

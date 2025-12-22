class Product < ApplicationRecord
  # Associations
  belongs_to :post, optional: true  # Make optional for standalone products
  has_many_attached :images

  # Delegations
  delegate :user, to: :post, allow_nil: true
  delegate :location_code, to: :post, allow_nil: true

  # Enums
  enum :condition, {
    new_item: 0,
    like_new: 1,
    good: 2,
    fair: 3,
    poor: 4
  }

  # Serializations
  serialize :images, coder: JSON, type: Array

  # Validations
  validates :name, presence: true, length: { maximum: 100 }, if: -> { post&.marketplace? }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }, if: -> { post&.marketplace? }
  validates :currency, inclusion: { in: %w[KRW VND USD] }
  validates :condition, presence: true, if: -> { post&.marketplace? }
  validates :images, limit: { max: 10 },
                     content_type: %i[png jpg jpeg webp],
                     size: { less_than: 10.megabytes },
                     if: :images_attached?

  # Scopes
  scope :available, -> { where(sold: false) }
  scope :sold, -> { where(sold: true) }
  scope :by_price_range, ->(min, max) { where(price: min..max) }

  # Callbacks
  before_validation :set_defaults

  # Instance methods
  def available?
    !sold?
  end

  def price_in_krw
    case currency
    when "VND"
      (price * 0.055).round # Approximate VND to KRW conversion
    when "USD"
      (price * 1300).round # Approximate USD to KRW conversion
    else
      price
    end
  end

  def condition_text(locale = I18n.locale)
    I18n.t("activerecord.attributes.product.conditions.#{condition}", locale: locale)
  end

  def images_attached?
    images.attached?
  end

  def require_marketplace_fields?
    post&.marketplace?
  end

  private

  def set_defaults
    self.currency ||= "KRW"
    self.sold ||= false
    self.name ||= post.title if post.present?
  end
end

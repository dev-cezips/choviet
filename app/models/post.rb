class Post < ApplicationRecord
  include Reportable

  # Associations
  belongs_to :user
  belongs_to :community, optional: true
  belongs_to :category, optional: true
  belongs_to :location, optional: true
  has_one :product, dependent: :destroy, inverse_of: :post, validate: false
  has_many :chat_rooms, dependent: :destroy
  has_many :likes, dependent: :destroy

  # Nested attributes
  accepts_nested_attributes_for :product, allow_destroy: true, reject_if: :reject_product?

  # Active Storage
  has_many_attached :images

  # Geocoding
  geocoded_by :latitude_longitude

  def latitude_longitude
    [ latitude, longitude ]
  end

  # Enums
  enum :post_type, {
    question: 0,      # 질문
    marketplace: 1,   # 중고거래
    free_talk: 2,     # 자유
    job: 3,
    housing: 4,
    service: 5
  }

  enum :status, {
    draft: 0,
    active: 1,
    sold: 2,
    expired: 3,
    deleted: 4
  }

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :by_location, ->(location_code) { where(location_code: location_code) }
  scope :for_koreans, -> { where(target_korean: true) }
  scope :recent, -> { order(created_at: :desc) }
  scope :questions, -> { where(post_type: "question") }
  scope :marketplace_posts, -> { where(post_type: "marketplace") }
  scope :free_talk, -> { where(post_type: "free_talk") }

  # Search scope - Vietnamese content focused
  scope :search_keyword, ->(keyword) {
    return all if keyword.blank?

    # Use ILIKE for case-insensitive search in PostgreSQL
    where("title ILIKE :q OR content ILIKE :q", q: "%#{sanitize_sql_like(keyword)}%")
  }

  # Location scopes - using geocoder's built-in near scope

  # Callbacks
  before_create :set_default_status

  # Validations
  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :content, presence: true, length: { minimum: 10 }
  validates :post_type, presence: true
  validates :images, limit: { max: 10 },
                     content_type: [ "image/png", "image/jpg", "image/jpeg", "image/gif" ],
                     size: { less_than: 5.megabytes }

  # Validate product attributes for marketplace posts
  validate :product_required_for_marketplace
  validate :minimum_images_for_marketplace
  validate :validate_product_if_marketplace

  def product_required_for_marketplace
    if marketplace? && (!product || product.price.blank?)
      errors.add(:base, "Giá bán là bắt buộc cho bài đăng mua bán")
    end
  end

  def minimum_images_for_marketplace
    if marketplace? && images.attached? && images.count < 5
      errors.add(:images, "Cần tối thiểu 5 hình ảnh cho bài đăng mua bán")
    end
  end

  # Callbacks
  before_validation :drop_product_unless_marketplace
  before_save :auto_translate_title, if: :target_korean_changed?
  before_create :set_location_from_user

  # Instance methods
  def marketplace?
    post_type == "marketplace"
  end

  def question?
    post_type == "question"
  end

  def sold_out!
    update(status: "sold")
    product&.update(sold: true)
  end

  def post_type_icon
    case post_type
    when "question"
      "question-mark-circle"
    when "marketplace"
      "shopping-bag"
    when "free_talk"
      "chat-bubble"
    when "job"
      "briefcase"
    else
      "document-text"
    end
  end

  def views_count
    read_attribute(:views_count) || 0
  end

  def comments_count
    # For MVP, we'll use chat_rooms count as comments
    chat_rooms.count
  end

  def liked_by?(user)
    return false unless user
    likes.exists?(user: user)
  end

  private

  def reject_product?(attributes)
    # id/currency/_destroy 같은 "의미 없는 값"은 빈값 판단에서 제외 (심볼/문자열 둘 다)
    ignore = ["_destroy", "id", "currency", :_destroy, :id, :currency]
    cleaned = attributes.except(*ignore)

    # 의미 있는 필드가 전부 비었으면 → 어떤 post_type이든 product 만들지 마
    return true if cleaned.values.all?(&:blank?)

    # 값이 들어왔는데 marketplace가 아니면 → product 받지 마
    return true unless marketplace?

    false
  end

  def validate_product_if_marketplace
    return unless marketplace?

    if product.nil?
      errors.add(:base, "Product is required for marketplace posts")
      return
    end

    return if product.valid?

    product.errors.each do |error|
      errors.add("product.#{error.attribute}", error.message)
    end
  end

  def drop_product_unless_marketplace
    return if marketplace?

    product&.mark_for_destruction
    self.product = nil
  end

  def set_default_status
    self.status ||= "active"
  end

  def auto_translate_title
    # This will be implemented with AI translation service
    # For now, just a placeholder
  end

  def set_location_from_user
    if user.has_location? && !latitude.present?
      self.latitude = user.latitude
      self.longitude = user.longitude
      self.location_code = user.location_code
      self.location = user.location
    end
  end
end

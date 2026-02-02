class Inquiry < ApplicationRecord
  # 관계
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  belongs_to :post, optional: true

  # 상태
  STATUSES = %w[pending read replied converted].freeze
  CONTACT_METHODS = %w[email kakao phone].freeze
  SOURCES = %w[organic profile featured_post ad_kakao ad_facebook].freeze

  # 유효성 검사
  validates :sender_name, presence: true
  validates :contact_method, presence: true, inclusion: { in: CONTACT_METHODS }
  validates :contact_value, presence: true
  validates :message, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :source, inclusion: { in: SOURCES }

  # 스코프 (대시보드/통계용)
  scope :pending, -> { where(status: "pending") }
  scope :read, -> { where(status: "read") }
  scope :replied, -> { where(status: "replied") }
  scope :converted, -> { where(status: "converted") }
  scope :for_recipient, ->(user) { where(recipient: user) }
  scope :from_post, ->(post) { where(post: post) }
  scope :recent, -> { order(created_at: :desc) }

  # 상태 전이
  def mark_as_read!
    return if read?

    update!(status: "read", read_at: Time.current)
  end

  def mark_as_replied!
    update!(status: "replied", replied_at: Time.current)
  end

  def mark_as_converted!
    update!(status: "converted")
  end

  # 상태 확인
  def pending?
    status == "pending"
  end

  def read?
    status == "read"
  end

  def replied?
    status == "replied"
  end

  def converted?
    status == "converted"
  end
end

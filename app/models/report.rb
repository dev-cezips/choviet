class Report < ApplicationRecord
  # Associations
  belongs_to :reporter, class_name: "User"
  belongs_to :reportable, polymorphic: true
  belongs_to :handled_by, class_name: "User", optional: true

  # Enums
  enum :status, {
    pending: "pending",
    reviewed: "reviewed",
    resolved: "resolved",
    dismissed: "dismissed"
  }
  
  enum :category, {
    spam: "spam",
    harassment: "harassment", 
    fraud: "fraud",
    inappropriate: "inappropriate",
    other: "other"
  }, prefix: true
  
  # Legacy support - keeping reason_code enum
  enum :reason_code, {
    spam: "spam",           # 스팸/홍보
    abusive: "abusive",     # 욕설/비방
    scam: "scam",          # 사기 의심
    inappropriate: "inappropriate"  # 부적절한 콘텐츠
  }, prefix: true

  # Validations
  validates :reason_code, presence: true
  validates :reporter_id, uniqueness: {
    scope: [:reportable_type, :reportable_id],
    message: "이미 신고하셨습니다"
  }
  validate :cannot_report_self

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_reason, ->(reason) { where(reason_code: reason) }
  scope :unhandled, -> { where(handled_at: nil) }
  scope :handled, -> { where.not(handled_at: nil) }
  scope :by_reportable_type, ->(type) { where(reportable_type: type) }

  # Callbacks
  after_create :increment_report_count
  after_create :auto_hide_if_threshold_reached
  after_create :check_auto_flag

  # Class methods
  # Instance methods
  def handle!(admin_user, action:, note: nil)
    update!(
      status: action,
      handled_by: admin_user,
      handled_at: Time.current,
      admin_note: note
    )
  end

  def self.reason_options_for_select(locale = :vi)
    case locale.to_s
    when "vi"
      [
        [ "🚫 Spam / Quảng cáo", "spam" ],
        [ "🤬 Ngôn từ đả kích", "abusive" ],
        [ "💸 Lừa đảo", "scam" ],
        [ "🔞 Nội dung không phù hợp", "inappropriate" ]
      ]
    when "ko"
      [
        [ "🚫 스팸 / 홍보", "spam" ],
        [ "🤬 욕설 / 비방", "abusive" ],
        [ "💸 사기 의심", "scam" ],
        [ "🔞 부적절한 콘텐츠", "inappropriate" ]
      ]
    else # English
      [
        [ "🚫 Spam / Advertising", "spam" ],
        [ "🤬 Abusive Language", "abusive" ],
        [ "💸 Scam / Fraud", "scam" ],
        [ "🔞 Inappropriate Content", "inappropriate" ]
      ]
    end
  end

  private

  def cannot_report_self
    if reportable_type == "User" && reportable_id == reporter_id
      errors.add(:base, "자기 자신을 신고할 수 없습니다")
    elsif reportable_type == "Post" && reportable&.user_id == reporter_id
      errors.add(:base, "자신의 게시물을 신고할 수 없습니다")
    elsif reportable_type == "Message" && reportable&.sender_id == reporter_id
      errors.add(:base, "자신의 메시지를 신고할 수 없습니다")
    elsif reportable_type == "ConversationMessage" && reportable&.user_id == reporter_id
      errors.add(:base, "자신의 메시지를 신고할 수 없습니다")
    end
  end

  def increment_report_count
    # Track report counts for analytics
    Rails.cache.increment("reports:#{reportable_type}:#{reportable_id}:count")
  end

  def auto_hide_if_threshold_reached
    # Auto-hide content if it reaches 3 reports
    if reportable.reports.count >= 3
      if reportable.respond_to?(:status)
        if reportable.class.defined_enums["status"]&.key?("hidden")
          reportable.update(status: "hidden")
        elsif reportable.class.defined_enums["status"]&.key?("deleted")
          reportable.update(status: "deleted")
        end
      elsif reportable.respond_to?(:visibility)
        reportable.update(visibility: false)
      end
    end
  end

  def check_auto_flag
    # Only check for User reports
    return unless reportable_type == "User"

    reported_user = reportable
    if reported_user.auto_flagged?
      # Find all chat rooms where the reported user is involved
      chat_rooms = ChatRoom.where(buyer: reported_user)
                          .or(ChatRoom.where(seller: reported_user))
                          .active

      chat_rooms.each do |room|
        # Check if warning message already exists
        existing_warning = room.messages
                              .where(system_message: true)
                              .where("content_raw LIKE ?", "%🚨%")
                              .exists?

        unless existing_warning
          room.messages.create!(
            sender_id: nil,
            system_message: true,
            content_raw: "💡 Thông báo từ hệ thống: Người dùng này có một số phản hồi chưa tích cực. Chúng tôi khuyến nghị bạn trao đổi kỹ lưỡng trước khi giao dịch.",
            content_translated: "💡 System notice: This user has received some negative feedback. We recommend thorough communication before trading.",
            src_lang: "vi"
          )
        end
      end
    end
  end
end

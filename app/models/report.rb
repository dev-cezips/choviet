class Report < ApplicationRecord
  # Associations
  belongs_to :reporter, class_name: "User"
  belongs_to :reported, polymorphic: true
  
  # Enums
  enum :reason_code, {
    spam: 'spam',           # 스팸/홍보
    abusive: 'abusive',     # 욕설/비방
    scam: 'scam',          # 사기 의심
    inappropriate: 'inappropriate'  # 부적절한 콘텐츠
  }
  
  enum :status, {
    pending: 'pending',     # 대기중
    resolved: 'resolved',   # 처리됨
    dismissed: 'dismissed'  # 기각됨
  }
  
  # Validations
  validates :reason_code, presence: true
  validates :reporter_id, uniqueness: { 
    scope: [:reported_type, :reported_id], 
    message: "이미 신고하셨습니다" 
  }
  validate :cannot_report_self
  
  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_reason, ->(reason) { where(reason_code: reason) }
  
  # Callbacks
  after_create :increment_report_count
  after_create :auto_hide_if_threshold_reached
  after_create :check_auto_flag
  
  # Class methods
  def self.reason_options_for_select(locale = :vi)
    if locale.to_s == 'vi'
      [
        ['🚫 Spam / Quảng cáo', 'spam'],
        ['🤬 Ngôn từ đả kích', 'abusive'],
        ['💸 Lừa đảo', 'scam'],
        ['🔞 Nội dung không phù hợp', 'inappropriate']
      ]
    else
      [
        ['🚫 스팸 / 홍보', 'spam'],
        ['🤬 욕설 / 비방', 'abusive'],
        ['💸 사기 의심', 'scam'],
        ['🔞 부적절한 콘텐츠', 'inappropriate']
      ]
    end
  end
  
  private
  
  def cannot_report_self
    if reported_type == 'User' && reported_id == reporter_id
      errors.add(:base, "자기 자신을 신고할 수 없습니다")
    elsif reported_type == 'Post' && reported&.user_id == reporter_id
      errors.add(:base, "자신의 게시물을 신고할 수 없습니다")
    end
  end
  
  def increment_report_count
    # Track report counts for analytics
    Rails.cache.increment("reports:#{reported_type}:#{reported_id}:count")
  end
  
  def auto_hide_if_threshold_reached
    # Auto-hide content if it reaches 3 reports
    if reported.reports.count >= 3 && reported.respond_to?(:status)
      reported.update(status: 'hidden')
    end
  end
  
  def check_auto_flag
    # Only check for User reports
    return unless reported_type == 'User'
    
    reported_user = reported
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
            src_lang: 'vi'
          )
        end
      end
    end
  end
end
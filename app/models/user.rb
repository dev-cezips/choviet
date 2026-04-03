class User < ApplicationRecord
  include Reportable

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2, :apple, :kakao ]

  # OmniAuth - find or create user from OAuth data
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name

      # Set avatar from OAuth if available
      if auth.info.image.present?
        # For now, just store the URL - can download and attach later
        # user.remote_avatar_url = auth.info.image
      end
    end
  end

  # Allow users to update without password (for OAuth users)
  def password_required?
    provider.blank? && super
  end

  # Geocoding
  geocoded_by :latitude_longitude

  def latitude_longitude
    [ latitude, longitude ]
  end

  # Associations
  has_many :posts, dependent: :destroy
  has_many :sent_messages, class_name: "Message", foreign_key: "sender_id"
  has_many :submitted_reports, class_name: "Report", foreign_key: "reporter_id"
  has_many :reports, as: :reportable, dependent: :destroy
  has_many :community_memberships, dependent: :destroy
  has_many :communities, through: :community_memberships
  belongs_to :location, optional: true
  has_many :likes
  has_many :liked_posts, through: :likes, source: :post
  has_many :favorites, dependent: :destroy
  has_many :favorite_posts, through: :favorites, source: :post
  has_many :reviews_given, class_name: "Review", foreign_key: :reviewer_id, dependent: :destroy
  has_many :reviews_received, class_name: "Review", foreign_key: :reviewee_id, dependent: :destroy

  # Blocking associations
  has_many :blocks_given, class_name: "Block", foreign_key: "blocker_id", dependent: :destroy
  has_many :blocks_received, class_name: "Block", foreign_key: "blocked_id", dependent: :destroy
  has_many :blocked_users, through: :blocks_given, source: :blocked
  has_many :blocked_by_users, through: :blocks_received, source: :blocker

  # Push notifications
  has_many :push_endpoints, dependent: :destroy
  has_many :notifications_received, class_name: "Notification", foreign_key: "recipient_id", dependent: :destroy
  has_many :notifications_sent, class_name: "Notification", foreign_key: "actor_id", dependent: :destroy

  # Avatar attachment
  has_one_attached :avatar

  # Title associations
  has_many :user_titles, dependent: :destroy
  has_many :titles, through: :user_titles
  has_one :primary_user_title, -> { where(primary: true) }, class_name: "UserTitle"
  has_one :primary_title, through: :primary_user_title, source: :title

  # Chat rooms where user is buyer
  has_many :buyer_chat_rooms, class_name: "ChatRoom", foreign_key: "buyer_id"
  # Chat rooms where user is seller
  has_many :seller_chat_rooms, class_name: "ChatRoom", foreign_key: "seller_id"

  # New 1:1 conversations
  has_many :conversation_participants, dependent: :destroy
  has_many :conversations, through: :conversation_participants
  has_many :conversation_messages

  # Inquiries (문의하기 - 수익화 핵심)
  has_many :sent_inquiries, class_name: "Inquiry", foreign_key: "sender_id", dependent: :destroy
  has_many :received_inquiries, class_name: "Inquiry", foreign_key: "recipient_id", dependent: :destroy

  # All chat rooms for the user
  def chat_rooms
    ChatRoom.where("buyer_id = ? OR seller_id = ?", id, id)
  end

  # Validations
  validates :locale, inclusion: { in: %w[vi ko en] }, allow_nil: true
  validates :location_code, presence: true, on: :update
  validates :location_radius, inclusion: { in: [ 1, 3, 5 ] }, allow_nil: true

  # Default values
  after_initialize :set_defaults, if: :new_record?

  def set_defaults
    self.locale ||= "vi"
    self.reputation_score ||= 0
    self.location_radius ||= 3
  end

  # Reputation methods
  def calculate_reputation_score
    return 0.0 if reviews_received.count == 0
    reviews_received.average(:rating).round(1)
  end

  def reputation_display
    score = calculate_reputation_score
    count = reviews_received.count

    if count == 0
      "Chưa có đánh giá"
    else
      "⭐ #{score} (#{count} đánh giá)"
    end
  end

  def update_reputation_score!
    update(reputation_score: calculate_reputation_score)
  end

  def reputation_timeline
    reviews_received.public_reviews.includes(:reviewer).order(created_at: :desc).limit(10)
  end

  # Risk assessment methods
  def low_reputation?
    reputation_score.present? && reputation_score < (TRUST_POLICY[:low_reputation_threshold] rescue 2.5)
  end

  def no_reviews?
    # 개발 환경에서는 리뷰 제한 우회
    return false if Rails.env.development?

    reviews_received.count < (TRUST_POLICY[:min_reviews_for_trade] rescue 1)
  end

  def risky_user?
    low_reputation? || no_reviews?
  end

  def auto_flagged?
    report_count >= (TRUST_POLICY[:auto_warning_reports] rescue 3)
  end

  # First trade helpers
  def first_trade?
    # Check if user has any completed trades (as buyer or seller)
    completed_trades_count == 0
  end

  def completed_first_sale?
    first_sale_at.present?
  end

  def completed_first_purchase?
    first_purchase_at.present?
  end

  def just_completed_first_sale?
    # Recently completed first sale (within last hour)
    first_sale_at.present? && first_sale_at > 1.hour.ago
  end

  def just_completed_first_purchase?
    # Recently completed first purchase (within last hour)
    first_purchase_at.present? && first_purchase_at > 1.hour.ago
  end

  def should_prompt_story_after_first_trade?
    # Prompt if completed first trade but no story yet
    (completed_first_sale? || completed_first_purchase?) && story.blank?
  end

  def completed_trades_count
    # Count completed trades where user is either buyer or seller
    ChatRoom.where("(buyer_id = :user_id OR seller_id = :user_id) AND trade_status = :status",
                   user_id: id, status: ChatRoom.trade_statuses[:completed]).count
  end

  def sales_count
    ChatRoom.where(seller_id: id, trade_status: :completed).count
  end

  def purchases_count
    ChatRoom.where(buyer_id: id, trade_status: :completed).count
  end

  # Growth stats for profile display
  def growth_stats
    trades = completed_trades_count
    reviews = reviews_received.count
    days = (Date.current - created_at.to_date).to_i

    {
      trades: trades,
      sales: sales_count,
      purchases: purchases_count,
      reviews_received: reviews,
      reviews_given: reviews_given.count,
      member_days: days,
      member_months: (days / 30.0).floor,
      next_milestone: next_trade_milestone(trades),
      current_milestone: current_trade_milestone(trades),
      growth_message: growth_message(trades, reviews, days)
    }
  end

  def next_trade_milestone(trades)
    milestones = [1, 5, 10, 25, 50, 100, 250, 500, 1000]
    milestones.find { |m| m > trades } || nil
  end

  def current_trade_milestone(trades)
    milestones = [1000, 500, 250, 100, 50, 25, 10, 5, 1]
    milestones.find { |m| trades >= m } || 0
  end

  def growth_message(trades, reviews, days)
    if trades == 0
      "🌱 Đang bắt đầu hành trình"
    elsif trades < 5
      "🌿 Những bước đầu tiên"
    elsif trades < 10
      "🌳 Đang phát triển"
    elsif trades < 25
      "⭐ Thành viên tích cực"
    elsif trades < 50
      "🌟 Người bán có uy tín"
    elsif trades < 100
      "💫 Người bán chuyên nghiệp"
    else
      "👑 Trụ cột cộng đồng"
    end
  end

  def milestone_just_reached?
    trades = completed_trades_count
    [1, 5, 10, 25, 50, 100].include?(trades)
  end

  def milestone_title(milestone)
    case milestone
    when 1 then "Giao dịch đầu tiên"
    when 5 then "5 giao dịch"
    when 10 then "10 giao dịch"
    when 25 then "25 giao dịch"
    when 50 then "50 giao dịch"
    when 100 then "100 giao dịch"
    else "#{milestone} giao dịch"
    end
  end

  # Trust summary - returns a single line description of user's trust level based on context
  def trust_summary(context: :default)
    case context
    when :post
      trust_summary_for_post
    when :chat
      trust_summary_for_chat
    when :profile
      trust_summary_for_profile
    else
      trust_summary_for_default
    end
  end

  # Activity tracking methods
  def last_activity_at
    [
      sent_messages.order(created_at: :desc).limit(1).pluck(:created_at).first,
      posts.order(created_at: :desc).limit(1).pluck(:created_at).first,
      reviews_given.order(created_at: :desc).limit(1).pluck(:created_at).first
    ].compact.max
  end

  def recently_active?(within: 7.days)
    last_activity_at.present? && last_activity_at > within.ago
  end

  def recent_trades_count(within: 14.days)
    ChatRoom.where(
      "(buyer_id = :id OR seller_id = :id) AND updated_at > :time",
      id: id,
      time: within.ago
    ).count
  end

  # Trust hint - provides gentle action suggestions based on trust state
  def trust_hint(context: :default)
    # Only show hints for new users or users with low recent activity
    return nil if first_trade? == false && recently_active?(within: 30.days)

    if first_trade?
      "💬 Hãy bắt đầu bằng việc hỏi rõ giá và cách giao hàng"
    elsif recently_active?(within: 7.days)
      "⏱ Người này thường phản hồi nhanh"
    elsif recently_active?(within: 30.days)
      "💬 Nên trao đổi rõ điều kiện trước khi chốt giao dịch"
    else
      "💬 Bạn nên nhắn tin trước khi quyết định giao dịch"
    end
  end

  private

  # Trust summary for post context
  def trust_summary_for_post
    reviews_count = reviews_received.count

    # For new users, always show new user message
    if first_trade? && reviews_count == 0
      return "🌱 Người dùng mới sẵn sàng cho giao dịch đầu tiên"
    end

    # Check activity timeline
    if recently_active?(within: 7.days)
      if reviews_count >= 5
        "⚡ Đang hoạt động với nhiều đánh giá tích cực"
      else
        "⚡ Gần đây có hoạt động giao dịch"
      end
    elsif recently_active?(within: 30.days)
      if reviews_count >= 3
        "💡 Có hoạt động trong tháng qua với #{reviews_count} đánh giá"
      else
        "💡 Có hoạt động trong thời gian gần đây"
      end
    else
      if reviews_count >= 5
        "🌙 Gần đây ít hoạt động nhưng có #{reviews_count} đánh giá từ trước"
      else
        "🌙 Gần đây ít hoạt động trên Chợ Việt"
      end
    end
  end

  # Trust summary for chat context
  def trust_summary_for_chat
    last_message = sent_messages.order(created_at: :desc).first
    response_time_good = last_message && last_message.created_at > 1.hour.ago

    # For new users
    if first_trade?
      return "🌱 Giao dịch đầu tiên, hãy hướng dẫn thêm nếu cần"
    end

    # Check recent activity and response pattern
    if recently_active?(within: 3.days)
      if response_time_good
        "⚡ Đang trực tuyến và phản hồi nhanh"
      else
        "⚡ Đang hoạt động trong vài ngày qua"
      end
    elsif recently_active?(within: 7.days)
      "💬 Có hoạt động trong tuần này"
    elsif recently_active?(within: 30.days)
      "💡 Có hoạt động trong tháng qua"
    else
      "🌙 Đang quay lại sau thời gian vắng mặt"
    end
  end

  # Trust summary for profile context
  def trust_summary_for_profile
    reviews_count = reviews_received.count
    completed_trades = completed_trades_count
    recent_trades = recent_trades_count(within: 30.days)

    # For brand new users
    if completed_trades == 0 && reviews_count == 0
      return "🌱 Đang bắt đầu hành trình giao dịch"
    end

    # Check activity timeline
    if recently_active?(within: 7.days)
      if reviews_count >= 5
        "⚡ Hoạt động tích cực với #{reviews_count} đánh giá"
      elsif recent_trades >= 2
        "⚡ Đang giao dịch thường xuyên"
      else
        "⚡ Có hoạt động trong tuần này"
      end
    elsif recently_active?(within: 30.days)
      if reviews_count >= 3
        "💡 Hoạt động trong tháng qua, #{reviews_count} đánh giá tích lũy"
      else
        "💡 Có hoạt động trong tháng gần đây"
      end
    else
      if reviews_count >= 5
        "🌙 Ít hoạt động gần đây, có #{reviews_count} đánh giá từ trước"
      else
        "🌙 Đã lâu không hoạt động trên Chợ Việt"
      end
    end
  end

  # Trust summary default fallback
  def trust_summary_for_default
    reviews_count = reviews_received.count

    if reviews_count == 0
      "👤 Thành viên Chợ Việt"
    else
      "👤 Có #{reviews_count} đánh giá từ cộng đồng"
    end
  end

  public

  # Instance methods
  def vietnamese?
    locale == "vi"
  end

  def korean?
    locale == "ko"
  end

  def onboarding_completed?
    onboarding_completed == true
  end

  def needs_onboarding?
    !onboarding_completed?
  end

  def display_name
    name.presence || email.split("@").first
  end

  # Blocking methods
  def blocking?(other_user)
    blocked_users.exists?(other_user.id)
  end

  def blocked_by?(other_user)
    blocked_by_users.exists?(other_user.id)
  end

  def blocked_with?(other_user)
    Block.blocked?(self, other_user)
  end

  # Push notification methods
  def push_enabled?
    notification_push_enabled != false
  end

  def dm_notifications_enabled?
    notification_dm_enabled != false
  end

  def all_chat_rooms
    ChatRoom.where("buyer_id = ? OR seller_id = ?", id, id)
  end

  # Location methods
  def has_location?
    latitude.present? && longitude.present?
  end

  def nearby_posts(radius = nil)
    return Post.none unless has_location?

    radius ||= location_radius
    Post.near([ latitude, longitude ], radius)
  end

  def nearby_users(radius = nil)
    return User.none unless has_location?

    radius ||= location_radius
    User.where.not(id: id)
        .where.not(latitude: nil, longitude: nil)
        .near([ latitude, longitude ], radius)
  end

  def update_location(lat, lng)
    update(latitude: lat, longitude: lng)
    # Auto-detect location based on coordinates
    detected_location = Location.near([ lat, lng ], 5).first
    update(location: detected_location) if detected_location
  end

  # 안 읽은 메시지 총 개수 계산
  def total_unread_messages
    # 내가 참여 중인 모든 채팅방에서, 상대방이 보냈고 && 내가 아직 안 읽은(read_at: nil) 메시지 수
    Message.joins(:chat_room)
           .where("chat_rooms.buyer_id = :user_id OR chat_rooms.seller_id = :user_id", user_id: id)
           .where.not(sender_id: id) # 내가 보낸 건 제외
           .where(read_at: nil)      # 안 읽은 것만
           .count
  end

  # 특정 채팅방의 안 읽은 메시지 수
  def unread_messages_for_chat_room(chat_room)
    chat_room.messages
             .where.not(sender_id: id)
             .where(read_at: nil)
             .count
  end

  # EXP and Level system
  def add_exp!(amount)
    new_exp = self.exp + amount
    new_level = calculate_level_from_exp(new_exp)

    # Level up happened
    if new_level > self.level
      update!(exp: new_exp, level: new_level)
      grant_level_titles!
      # TODO: Send level up notification
    else
      update!(exp: new_exp)
    end
  end

  def exp_for_next_level
    exp_required_for_level(level + 1)
  end

  def exp_progress_percentage
    current_level_exp = exp_required_for_level(level)
    next_level_exp = exp_required_for_level(level + 1)
    progress_exp = exp - current_level_exp
    total_needed = next_level_exp - current_level_exp

    (progress_exp.to_f / total_needed * 100).round(2)
  end

  # Title methods
  def grant_title!(title_key)
    title = Title.find_by_key(title_key)
    return false unless title
    return false if titles.include?(title)

    user_titles.create!(title: title)
    true
  end

  def has_title?(title_key)
    titles.joins(:user_titles).where(key: title_key).exists?
  end

  def set_primary_title!(title_key)
    title = titles.find_by(key: title_key)
    return false unless title

    user_titles.update_all(primary: false)
    user_titles.find_by(title: title).update!(primary: true)
    true
  end

  private

  def calculate_level_from_exp(total_exp)
    # Level calculation formula: Level = floor(sqrt(exp / 100))
    # This gives a nice progression curve
    [ 1, Math.sqrt(total_exp / 100.0).floor ].max
  end

  def exp_required_for_level(level)
    # Reverse formula: exp = level^2 * 100
    level ** 2 * 100
  end

  def grant_level_titles!
    Title.level_titles.for_level(level).each do |title|
      grant_title!(title.key)
    end
  end
end

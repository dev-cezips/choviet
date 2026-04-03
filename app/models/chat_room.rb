class ChatRoom < ApplicationRecord
  # Associations
  belongs_to :post
  belongs_to :buyer, class_name: "User"
  belongs_to :seller, class_name: "User"
  has_many :messages, dependent: :destroy
  has_many :reviews, dependent: :destroy

  # Enums
  enum :status, { active: 0, closed: 1, blocked: 2 }, default: :active
  enum :trade_status, { negotiating: 0, completed: 1, cancelled: 2 }, default: :negotiating

  # Callbacks
  after_save :track_first_trade, if: :saved_change_to_trade_status?

  # Validations
  validates :buyer_id, presence: true
  validates :seller_id, presence: true
  validate :buyer_and_seller_are_different
  validates :buyer_id, uniqueness: { scope: :post_id, message: "already has a chat room for this post" }

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :for_user, ->(user_id) { where("buyer_id = ? OR seller_id = ?", user_id, user_id) }
  scope :unread_for, ->(user_id) {
    joins(:messages)
      .where("messages.sender_id != ? AND messages.read_at IS NULL", user_id)
      .distinct
  }

  # Instance methods
  def other_user(current_user)
    current_user.id == buyer_id ? seller : buyer
  end

  def participant?(user)
    user.id == buyer_id || user.id == seller_id
  end

  def last_message
    messages.order(created_at: :desc).first
  end

  def unread_count_for(user)
    messages.where.not(sender_id: user.id).where(read_at: nil).count
  end

  def mark_as_read_for(user)
    messages.where.not(sender_id: user.id).where(read_at: nil).update_all(read_at: Time.current)
  end

  def reviewed_by?(user)
    reviews.exists?(reviewer_id: user.id)
  end

  def can_be_reviewed_by?(user)
    trade_status == "completed" && participant?(user) && !reviewed_by?(user)
  end

  def should_show_review_reminder?(user)
    # Show reminder if:
    # 1. Trade is completed
    # 2. User is a participant
    # 3. User hasn't reviewed yet
    # 4. It's been at least 24 hours since completion
    # 5. We haven't shown the reminder yet (check session/cookies in controller)
    return false unless trade_status == "completed"
    return false unless participant?(user)
    return false if reviewed_by?(user)

    # Find when the trade was completed
    completion_message = messages.where(system_message: true)
                                .where("content_raw LIKE ?", "%✅%")
                                .order(created_at: :desc)
                                .first

    return false unless completion_message

    # Check if it's been at least 24 hours
    completion_message.created_at <= 24.hours.ago
  end

  private

  def buyer_and_seller_are_different
    if buyer_id == seller_id
      errors.add(:buyer_id, "can't be the same as seller")
    end
  end

  # Track first trade completion for both buyer and seller
  def track_first_trade
    return unless trade_status == "completed"

    # Track first purchase for buyer
    if buyer.first_purchase_at.nil?
      buyer.update_columns(first_purchase_at: Time.current)
      buyer.grant_title!("first_purchase")
    end

    # Track first sale for seller
    if seller.first_sale_at.nil?
      seller.update_columns(first_sale_at: Time.current)
      seller.grant_title!("first_sale")
    end

    # Check and grant milestone titles for both users
    grant_milestone_titles(buyer)
    grant_milestone_titles(seller)
  end

  def grant_milestone_titles(user)
    trades = user.completed_trades_count
    milestones = { 10 => "milestone_10", 25 => "milestone_25", 50 => "milestone_50", 100 => "milestone_100" }

    milestones.each do |count, title_key|
      if trades >= count && !user.has_title?(title_key)
        user.grant_title!(title_key)
      end
    end
  end
end

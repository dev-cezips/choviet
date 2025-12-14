class Review < ApplicationRecord
  belongs_to :chat_room
  belongs_to :reviewer, class_name: 'User'
  belongs_to :reviewee, class_name: 'User'
  has_many :review_reactions, dependent: :destroy
  
  # Validations
  validates :rating, presence: true, inclusion: { in: 1..5 }
  validates :comment, length: { maximum: 500 }
  validates :reviewer_id, uniqueness: { scope: :chat_room_id, message: "đã đánh giá cho giao dịch này" }
  
  # Ensure reviewer and reviewee are different
  validate :reviewer_and_reviewee_are_different
  
  # Ensure the reviewer is part of the chat room
  validate :reviewer_is_participant
  
  # Ensure the chat room transaction is completed
  validate :transaction_must_be_completed
  
  # Callbacks
  after_create :update_reviewee_reputation
  
  # Scopes
  scope :public_reviews, -> { where(visibility: true) }
  
  # Instance methods
  def helpful_count
    review_reactions.where(helpful: true).count
  end
  
  def unhelpful_count
    review_reactions.where(helpful: false).count
  end
  
  def reacted_by?(user)
    return false unless user
    review_reactions.exists?(user_id: user.id)
  end
  
  def user_reaction(user)
    return nil unless user
    review_reactions.find_by(user_id: user.id)
  end
  
  private
  
  def reviewer_and_reviewee_are_different
    if reviewer_id == reviewee_id
      errors.add(:reviewer_id, "không thể tự đánh giá")
    end
  end
  
  def reviewer_is_participant
    return unless chat_room
    
    unless [chat_room.buyer_id, chat_room.seller_id].include?(reviewer_id)
      errors.add(:reviewer_id, "phải là người tham gia giao dịch")
    end
  end
  
  def transaction_must_be_completed
    return unless chat_room
    
    unless chat_room.trade_status == 'completed'
      errors.add(:base, "Chỉ có thể đánh giá sau khi giao dịch hoàn tất")
    end
  end
  
  def update_reviewee_reputation
    reviewee.update_reputation_score!
  end
end

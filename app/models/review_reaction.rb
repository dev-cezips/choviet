class ReviewReaction < ApplicationRecord
  belongs_to :review
  belongs_to :user
  
  # Validations
  validates :user_id, uniqueness: { scope: :review_id, message: "đã phản hồi về đánh giá này" }
  
  # Prevent users from reacting to their own reviews
  validate :cannot_react_to_own_review
  
  private
  
  def cannot_react_to_own_review
    if review && review.reviewer_id == user_id
      errors.add(:base, "Không thể đánh giá review của chính mình")
    end
  end
end

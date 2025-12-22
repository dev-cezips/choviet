class ReviewsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat_room
  before_action :check_participant
  before_action :check_can_review, only: [ :new, :create ]

  def new
    @review = @chat_room.reviews.build
    @reviewee = @chat_room.other_user(current_user)
  end

  def create
    @review = @chat_room.reviews.build(review_params)
    @review.reviewer = current_user
    @review.reviewee = @chat_room.other_user(current_user)

    if @review.save
      # Create system message about review completion
      @chat_room.messages.create!(
        sender_id: nil,
        system_message: true,
        content_raw: "⭐ #{current_user.display_name} đã hoàn thành đánh giá giao dịch.",
        content_translated: "⭐ #{current_user.display_name} has completed the transaction review.",
        src_lang: "vi"
      )

      track_event("review_created", {
        chat_room_id: @chat_room.id,
        reviewer_id: current_user.id,
        reviewee_id: @review.reviewee_id,
        rating: @review.rating
      })

      # Check if this is user's first review
      first_review = current_user.reviews_given.count == 1

      # Create reward flash message
      flash[:reward] = if first_review
        {
          title: "🎉 Chúc mừng đánh giá đầu tiên!",
          message: "Bạn vừa nhận được +0.5 điểm uy tín. Cộng đồng sẽ tin tưởng bạn hơn!",
          first_review: true
        }
      else
        {
          title: "🎉 Cảm ơn bạn đã đánh giá!",
          message: "Điểm uy tín của bạn đã tăng +0.2. Mỗi đánh giá giúp cộng đồng an toàn hơn!",
          first_review: false
        }
      end

      redirect_to post_chat_room_path(@post, @chat_room)
    else
      @reviewee = @chat_room.other_user(current_user)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_chat_room
    @post = Post.find(params[:post_id])
    @chat_room = @post.chat_rooms.find(params[:chat_room_id])
  end

  def check_participant
    unless @chat_room.participant?(current_user)
      redirect_to root_path, alert: "Bạn không có quyền đánh giá giao dịch này."
    end
  end

  def check_can_review
    unless @chat_room.can_be_reviewed_by?(current_user)
      redirect_to post_chat_room_path(@post, @chat_room), alert: "Bạn không thể đánh giá giao dịch này."
    end
  end

  def review_params
    params.require(:review).permit(:rating, :comment, :visibility)
  end

  def track_event(event_name, data)
    # Placeholder for event tracking
    Rails.logger.info("Event: #{event_name}, Data: #{data}")
  end
end

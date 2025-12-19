class ChatRoomsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat_room, only: [ :show, :update_status, :dismiss_review_reminder ]
  before_action :check_participant, only: [ :show, :dismiss_review_reminder ]
  before_action :check_seller, only: [ :update_status ]

  def index
    @chat_rooms = ChatRoom.for_user(current_user.id)
                          .includes(:post, :buyer, :seller, :messages)
                          .order(updated_at: :desc)
  end

  def show
    @messages = @chat_room.messages.includes(:sender).order(:created_at)
    @message = Message.new
    @quick_replies = QuickReply.all

    # Mark messages as read for current user
    @messages.where.not(sender: current_user).where(read_at: nil).update_all(read_at: Time.current)

    # Check if we should show review reminder
    @show_review_reminder = false
    if @chat_room.should_show_review_reminder?(current_user)
      # Check if user hasn't dismissed it yet (using session)
      session_key = "dismissed_review_reminder_#{@chat_room.id}"
      @show_review_reminder = !session[session_key]
    end
  end

  def create
    @post = Post.find(params[:post_id])

    # Check if user has no reviews
    if current_user.no_reviews?
      redirect_to post_path(@post),
        alert: "Để đảm bảo an toàn cho mọi người, bạn cần hoàn thành một giao dịch và nhận đánh giá trước nhé! 🌟"
      return
    end

    # Check if chat room already exists
    existing = ChatRoom.exists?(
      post: @post,
      buyer_id: current_user.id,
      seller_id: @post.user_id
    )

    @chat_room = ChatRoom.find_or_create_by!(
      post: @post,
      buyer_id: current_user.id,
      seller_id: @post.user_id
    )

    unless existing
      track_event("chat_room_created", {
        post_id: @post.id,
        post_type: @post.post_type,
        seller_id: @post.user_id,
        buyer_id: current_user.id
      })

      # Add first trade guidance message for new users
      if current_user.first_trade?
        # Check if first trade message already exists
        existing_first_trade_msg = @chat_room.messages
                                            .where(system_message: true)
                                            .where("content_raw LIKE ?", "%💡 Hướng dẫn giao dịch đầu tiên%")
                                            .exists?

        unless existing_first_trade_msg
          @chat_room.messages.create!(
            sender_id: nil,
            system_message: true,
            content_raw: "💡 Hướng dẫn giao dịch đầu tiên:\n• Xác nhận rõ giá cả và tình trạng sản phẩm\n• Hẹn gặp ở nơi công cộng an toàn\n• Kiểm tra kỹ sản phẩm trước khi thanh toán\n• Giữ mọi trao đổi trong ứng dụng",
            content_translated: "💡 First trade guide:\n• Confirm price and product condition clearly\n• Meet in a safe public place\n• Check the product carefully before payment\n• Keep all communication within the app",
            src_lang: "vi"
          )
        end
      end
    end

    redirect_to post_chat_room_path(@post, @chat_room)
  end

  def update_status
    # Accept both params[:status] and params[:trade_status] for compatibility
    status = params[:status] || params[:trade_status]

    # Prevent duplicate status updates
    if @chat_room.trade_status == status
      redirect_to post_chat_room_path(@post, @chat_room)
      return
    end

    # Store the previous status to check if we're transitioning to completed
    previous_status = @chat_room.trade_status

    if @chat_room.update(trade_status: status)
      flash[:notice] = case status
      when "completed" then "Giao dịch đã được đánh dấu hoàn tất"
      when "cancelled" then "Giao dịch đã bị hủy"
      when "negotiating" then "Giao dịch đã được mở lại"
      else "Trạng thái đã được cập nhật"
      end

      # Create system message for completed transactions only if transitioning to completed
      if status == "completed" && previous_status != "completed"
        # Check if completion message already exists
        existing_completion = @chat_room.messages
                                      .where(system_message: true)
                                      .where("content_raw LIKE ?", "%✅%")
                                      .exists?

        unless existing_completion
          # Check if this is the user's first completed trade
          buyer_first_trade = @chat_room.buyer.completed_trades_count == 1
          seller_first_trade = @chat_room.seller.completed_trades_count == 1

          if buyer_first_trade || seller_first_trade
            # Special message for first trade completion
            @chat_room.messages.create!(
              sender_id: nil,
              system_message: true,
              content_raw: "🎉 Chúc mừng! Đây là giao dịch đầu tiên được hoàn thành!\n✅ Giao dịch thành công. Đừng quên đánh giá để xây dựng uy tín nhé!",
              content_translated: "🎉 Congratulations! This is your first completed trade!\n✅ Transaction successful. Don't forget to leave a review to build your reputation!",
              src_lang: "vi"
            )
          else
            # Regular completion message
            @chat_room.messages.create!(
              sender_id: nil,
              system_message: true,
              content_raw: "✅ Giao dịch đã hoàn tất. Cảm ơn bạn đã sử dụng Chợ Việt!",
              content_translated: "✅ Transaction completed. Thank you for using Chợ Việt!",
              src_lang: "vi"
            )
          end
        end
      end

      track_event("trade_status_updated", {
        chat_room_id: @chat_room.id,
        post_id: @post.id,
        new_status: status,
        previous_status: previous_status,
        seller_id: @chat_room.seller_id
      })
    else
      flash[:alert] = "Không thể cập nhật trạng thái"
    end

    redirect_to post_chat_room_path(@post, @chat_room)
  end

  def dismiss_review_reminder
    session["dismissed_review_reminder_#{@chat_room.id}"] = true
    head :ok
  end

  private

  def set_chat_room
    @chat_room = ChatRoom.find(params[:id])
    @post = @chat_room.post
  end

  def check_participant
    unless [ @chat_room.buyer_id, @chat_room.seller_id ].include?(current_user.id)
      redirect_to root_path, alert: I18n.t("chat_rooms.not_authorized")
    end
  end

  def check_seller
    unless current_user.id == @chat_room.seller_id
      redirect_to root_path, alert: "Chỉ người bán mới có thể cập nhật trạng thái giao dịch"
    end
  end
end

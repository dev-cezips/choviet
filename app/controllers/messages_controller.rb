class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_chat_room
  before_action :check_participant

  def new
    @message = @chat_room.messages.build
  end

  def create
    @message = @chat_room.messages.build(message_params)
    @message.sender = current_user
    @message.src_lang = current_user.locale || "vi"

    if @message.save
      # Queue translation job if needed
      needs_translation = should_translate?
      if needs_translation
        TranslateMessageJob.perform_later(@message.id)
      end

      track_event("message_sent", {
        chat_room_id: @chat_room.id,
        post_id: @post.id,
        message_length: @message.content_raw.length,
        needs_translation: needs_translation,
        quick_reply_used: params[:quick_reply].present?
      })

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to post_chat_room_path(@post, @chat_room) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_chat_room
    @post = Post.find(params[:post_id])
    @chat_room = @post.chat_rooms.find(params[:chat_room_id])
  end

  def check_participant
    unless [ @chat_room.buyer_id, @chat_room.seller_id ].include?(current_user.id)
      redirect_to root_path, alert: I18n.t("chat_rooms.not_authorized")
    end
  end

  def message_params
    params.require(:message).permit(:content_raw)
  end

  def should_translate?
    # Translate if participants have different locales
    buyer = User.find(@chat_room.buyer_id)
    seller = User.find(@chat_room.seller_id)
    buyer.locale != seller.locale
  end
end

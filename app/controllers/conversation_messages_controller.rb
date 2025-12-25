class ConversationMessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation
  before_action :authorize_participant!
  
  def create
    @message = @conversation.conversation_messages.build(message_params)
    @message.user = current_user
    
    if @message.save
      # Turbo will handle the real-time update via after_create_commit callback
      respond_to do |format|
        format.turbo_stream { head :ok }
        format.html { redirect_to @conversation }
      end
    else
      respond_to do |format|
        format.turbo_stream { 
          render turbo_stream: turbo_stream.replace(
            "message_form",
            partial: "conversation_messages/form",
            locals: { conversation: @conversation, message: @message }
          )
        }
        format.html { 
          redirect_to @conversation, alert: "Tin nhắn không thể gửi: #{@message.errors.full_messages.join(', ')}"
        }
      end
    end
  end
  
  private
  
  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end
  
  def authorize_participant!
    unless @conversation.includes_user?(current_user)
      redirect_to root_path, alert: "Bạn không có quyền trong cuộc trò chuyện này"
    end
  end
  
  def message_params
    params.require(:conversation_message).permit(:body)
  end
end
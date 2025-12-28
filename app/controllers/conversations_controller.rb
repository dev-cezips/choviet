class ConversationsController < ApplicationController
  include BlockGuard
  
  before_action :authenticate_user!
  before_action :set_conversation, only: [:show]
  before_action :authorize_participant!, only: [:show]
  
  def index
    @conversations = current_user.conversations
      .not_blocked_for(current_user)
      .includes(:conversation_participants, :conversation_messages, user_a: :avatar_attachment, user_b: :avatar_attachment)
      .joins(:conversation_messages)
      .order("conversation_messages.created_at DESC")
      .distinct
  end
  
  def show
    # Update last read timestamp when viewing conversation
    @participant = @conversation.conversation_participants.find_by!(user: current_user)
    @participant.mark_as_read!
    
    # Load messages
    @messages = @conversation.conversation_messages
      .includes(:user)
      .order(:created_at)
    
    # For the message form
    @message = @conversation.conversation_messages.build
    
    # Get the other user for display
    @other_user = @conversation.other_user(current_user)
  end
  
  def create_from_post
    @post = Post.find(params[:id])
    
    # Can't DM yourself
    if @post.user == current_user
      redirect_to @post, alert: "Bạn không thể nhắn tin cho chính mình"
      return
    end
    
    # Check if blocked
    if Block.blocked?(current_user, @post.user)
      redirect_to @post, alert: blocking_error_message
      return
    end
    
    # Find or create conversation
    @conversation = Conversation.find_or_create_direct(current_user, @post.user)
    
    redirect_to @conversation
  end
  
  private
  
  def set_conversation
    @conversation = Conversation.find(params[:id])
  end
  
  def authorize_participant!
    unless @conversation.includes_user?(current_user)
      redirect_to root_path, alert: "Bạn không có quyền truy cập cuộc trò chuyện này"
    end
  end
  
  # BlockGuard methods
  def requires_blocking_check?
    action_name == "show"
  end
  
  def other_user_for_blocking
    return nil unless @conversation
    @conversation.other_user(current_user)
  end
end
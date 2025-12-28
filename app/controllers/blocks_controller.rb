class BlocksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_blocked_user, only: [:create]
  before_action :set_block, only: [:destroy]

  def create
    @block = current_user.blocks_given.build(blocked: @blocked_user, reason: params[:reason])
    
    if @block.save
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, notice: block_success_message) }
        format.turbo_stream
        format.json { render json: { status: 'blocked', message: block_success_message } }
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: root_path, alert: @block.errors.full_messages.first) }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { flash: { alert: @block.errors.full_messages.first } }) }
        format.json { render json: { errors: @block.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @blocked_user = @block.blocked
    @block.destroy
    
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: unblock_success_message) }
      format.turbo_stream
      format.json { render json: { status: 'unblocked', message: unblock_success_message } }
    end
  end

  private

  def set_blocked_user
    @blocked_user = User.find(params[:blocked_id])
    
    # Can't block yourself
    if @blocked_user == current_user
      redirect_back(fallback_location: root_path, alert: self_block_error_message)
    end
  end

  def set_block
    @block = current_user.blocks_given.find(params[:id])
  end

  def block_success_message
    if current_user.locale == "ko"
      "사용자를 차단했습니다."
    else
      "Đã chặn người dùng."
    end
  end

  def unblock_success_message
    if current_user.locale == "ko"
      "차단을 해제했습니다."
    else
      "Đã bỏ chặn người dùng."
    end
  end

  def self_block_error_message
    if current_user.locale == "ko"
      "자기 자신을 차단할 수 없습니다."
    else
      "Bạn không thể tự chặn chính mình."
    end
  end
end
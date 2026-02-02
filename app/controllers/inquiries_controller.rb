class InquiriesController < ApplicationController
  before_action :set_recipient
  before_action :set_post, only: [:new, :create]

  # GET /users/:user_id/inquiries/new
  # 폼은 로그인 없이도 볼 수 있음
  def new
    @inquiry = Inquiry.new
  end

  # POST /users/:user_id/inquiries
  # 전송은 로그인 필수
  def create
    # 로그인 안 했으면 로그인 유도
    unless user_signed_in?
      # Turbo Native / Web 공통: JSON으로 로그인 필요 응답
      respond_to do |format|
        format.html do
          store_location_for(:user, request.fullpath)
          redirect_to new_user_session_path, alert: t("inquiries.login_required")
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "inquiry_form",
            partial: "inquiries/login_required"
          )
        end
        format.json { render json: { login_required: true }, status: :unauthorized }
      end
      return
    end

    @inquiry = @recipient.received_inquiries.build(inquiry_params)
    @inquiry.sender = current_user
    @inquiry.post = @post if @post

    # 소스 추적
    @inquiry.source = determine_source

    if @inquiry.save
      # 성공 응답
      respond_to do |format|
        format.html { redirect_to @post || user_path(@recipient), notice: t("inquiries.sent_success") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "inquiry_form",
            partial: "inquiries/success",
            locals: { inquiry: @inquiry }
          )
        end
        format.json { render json: { success: true, inquiry_id: @inquiry.id }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "inquiry_form",
            partial: "inquiries/form",
            locals: { inquiry: @inquiry, recipient: @recipient, post: @post }
          )
        end
        format.json { render json: { errors: @inquiry.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_recipient
    @recipient = User.find(params[:user_id])
  end

  def set_post
    @post = Post.find_by(id: params[:post_id])
  end

  def inquiry_params
    params.require(:inquiry).permit(:sender_name, :contact_method, :contact_value, :message)
  end

  def determine_source
    if params[:source].present? && Inquiry::SOURCES.include?(params[:source])
      params[:source]
    elsif @post.present?
      "organic"
    else
      "profile"
    end
  end
end

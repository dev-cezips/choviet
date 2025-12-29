class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reportable, only: [:new, :create]
  before_action :check_already_reported, only: [:new, :create]

  def new
    @report = @reportable.reports.build
  end

  def create
    @report = @reportable.reports.build(report_params)
    @report.reporter = current_user

    if @report.save
      track_event("report_created", {
        reportable_type: @report.reportable_type,
        reportable_id: @report.reportable_id,
        reason_code: @report.reason_code,
        has_description: @report.description.present?
      })

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("report_modal", ""),
            turbo_stream.prepend("flash_messages", partial: "shared/flash",
              locals: { type: :notice, message: I18n.t("reports.created") })
          ]
        end
        format.html do
          redirect_back(fallback_location: root_path, notice: I18n.t("reports.created"))
        end
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render :new, status: :unprocessable_entity
        end
        format.html do
          render :new, status: :unprocessable_entity
        end
      end
    end
  end

  private

  def set_reportable
    @reportable = find_reportable
  end

  def check_already_reported
    if @reportable.reported_by?(current_user)
      redirect_back(fallback_location: root_path, alert: already_reported_message)
    end
  end

  def find_reportable
    if params[:post_id]
      Post.find(params[:post_id])
    elsif params[:user_id]
      User.find(params[:user_id])
    elsif params[:message_id]
      Message.find(params[:message_id])
    elsif params[:conversation_message_id]
      message = ConversationMessage.find(params[:conversation_message_id])
      # Ensure user can only report messages in conversations they're part of
      unless message.conversation.includes_user?(current_user)
        raise ActiveRecord::RecordNotFound
      end
      message
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def report_params
    # Accept both reason_code and reason for backward compatibility
    permitted = params.require(:report).permit(:reason_code, :reason, :description)

    # If reason is provided but not reason_code, use reason as reason_code
    if permitted[:reason].present? && permitted[:reason_code].blank?
      permitted[:reason_code] = permitted[:reason]
    end

    # Remove reason from params to avoid confusion
    permitted.except(:reason)
  end

  def already_reported_message
    if current_user.vietnamese?
      "Bạn đã báo cáo nội dung này rồi."
    else
      "이미 신고한 콘텐츠입니다."
    end
  end
end

class ReportsController < ApplicationController
  before_action :authenticate_user!

  def new
    @reportable = find_reportable
    @report = @reportable.reports.build
  end

  def create
    @reportable = find_reportable
    @report = @reportable.reports.build(report_params)
    @report.reporter = current_user

    if @report.save
      track_event("report_created", {
        reportable_type: @report.reported_type,
        reportable_id: @report.reported_id,
        reason_code: @report.reason_code,
        has_description: @report.description.present?
      })
      
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("report_modal", ""),
            turbo_stream.prepend("flash_messages", partial: "shared/flash", 
              locals: { type: :notice, message: I18n.t('reports.created') })
          ]
        end
        format.html do
          redirect_back(fallback_location: root_path, notice: I18n.t('reports.created'))
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

  def find_reportable
    if params[:post_id]
      Post.find(params[:post_id])
    elsif params[:user_id]
      User.find(params[:user_id])
    elsif params[:message_id]
      Message.find(params[:message_id])
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  def report_params
    params.require(:report).permit(:reason_code, :description)
  end
end
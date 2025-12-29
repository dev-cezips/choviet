class Admin::ReportsController < Admin::BaseController
  before_action :set_report, only: [ :show, :resolve, :dismiss ]

  def index
    @reports = Report.includes(:reporter, :reportable, :handled_by)
                    .order(created_at: :desc)
    # .page(params[:page]) # TODO: Add pagination gem

    # Filters
    @reports = @reports.where(status: params[:status]) if params[:status].present?
    @reports = @reports.where(reportable_type: params[:type]) if params[:type].present?
    @reports = @reports.unhandled if params[:unhandled] == "true"

    @stats = {
      total: Report.count,
      pending: Report.pending.count,
      resolved: Report.resolved.count,
      dismissed: Report.dismissed.count
    }
  end

  def show
    # Load related reports for the same reportable
    @related_reports = Report.where(
      reportable_type: @report.reportable_type,
      reportable_id: @report.reportable_id
    ).where.not(id: @report.id)
  end

  def resolve
    @report.handle!(current_user, action: :resolved, note: params[:admin_note])
    # Optional: Take action on the reportable (e.g., hide post, suspend user)
    if params[:hide_content] == "true" && @report.reportable.respond_to?(:hide!)
      @report.reportable.hide!
    end
    redirect_to admin_reports_path, notice: resolve_success_message
  end

  def dismiss
    @report.handle!(current_user, action: :dismissed, note: params[:admin_note])
    redirect_to admin_reports_path, notice: dismiss_success_message
  end

  def batch_action
    report_ids = params[:report_ids] || []
    action = params[:batch_action]
    case action
    when "resolve"
      Report.where(id: report_ids).find_each do |report|
        report.handle!(current_user, action: :resolved)
      end
      redirect_to admin_reports_path, notice: batch_resolve_message(report_ids.size)
    when "dismiss"
      Report.where(id: report_ids).find_each do |report|
        report.handle!(current_user, action: :dismissed)
      end
      redirect_to admin_reports_path, notice: batch_dismiss_message(report_ids.size)
    else
      redirect_to admin_reports_path, alert: invalid_action_message
    end
  end

  private

  def set_report
    @report = Report.find(params[:id])
  end

  def resolve_success_message
    if current_user.vietnamese?
      "Đã xử lý báo cáo thành công."
    else
      "신고를 성공적으로 처리했습니다."
    end
  end

  def dismiss_success_message
    if current_user.vietnamese?
      "Đã bác bỏ báo cáo."
    else
      "신고를 기각했습니다."
    end
  end

  def batch_resolve_message(count)
    if current_user.vietnamese?
      "Đã xử lý #{count} báo cáo."
    else
      "#{count}개의 신고를 처리했습니다."
    end
  end

  def batch_dismiss_message(count)
    if current_user.vietnamese?
      "Đã bác bỏ #{count} báo cáo."
    else
      "#{count}개의 신고를 기각했습니다."
    end
  end

  def invalid_action_message
    if current_user.vietnamese?
      "Hành động không hợp lệ."
    else
      "유효하지 않은 작업입니다."
    end
  end
end

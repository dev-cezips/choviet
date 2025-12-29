module BlockGuard
  extend ActiveSupport::Concern

  included do
    before_action :check_blocking_status!, if: :requires_blocking_check?
  end

  private

  def check_blocking_status!
    return unless current_user && other_user_for_blocking

    if Block.blocked?(current_user, other_user_for_blocking)
      respond_to do |format|
        format.html do
          flash[:alert] = blocking_error_message
          redirect_to root_path
        end
        format.json do
          render json: { error: blocking_error_message }, status: :forbidden
        end
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "flash",
            partial: "shared/flash",
            locals: { flash: { alert: blocking_error_message } }
          )
        end
      end
    end
  end

  # Override in controllers to specify when to check blocking
  def requires_blocking_check?
    false
  end

  # Override in controllers to specify the other user
  def other_user_for_blocking
    nil
  end

  def blocking_error_message
    I18n.t(
      "errors.blocked_dm",
      default: "차단된 사용자와는 대화할 수 없습니다."
    )
  end
end
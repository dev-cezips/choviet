class Admin::BaseController < ApplicationController
  before_action :authenticate_admin!

  private

  def authenticate_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: admin_access_denied_message
    end
  end

  def admin_access_denied_message
    if current_user&.vietnamese?
      "Bạn không có quyền truy cập khu vực này."
    else
      "이 영역에 접근할 권한이 없습니다."
    end
  end
end
class NotificationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @notifications = current_user.notifications_received.recent.limit(50)
    @unread_count = current_user.notifications_received.unread.count

    # Mark all as read when viewing
    current_user.notifications_received.unread.update_all(read_at: Time.current)
  end

  def mark_read
    notification = current_user.notifications_received.find(params[:id])
    notification.update(read_at: Time.current)

    respond_to do |format|
      format.html { redirect_back fallback_location: notifications_path }
      format.turbo_stream { head :ok }
    end
  end

  def mark_all_read
    current_user.notifications_received.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: t("notifications.all_marked_read") }
      format.turbo_stream { head :ok }
    end
  end
end

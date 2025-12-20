class Admin::DashboardController < ApplicationController
  before_action :authenticate_admin!

  def index
    @stats = {
      # User metrics
      total_users: User.count,
      new_users_today: User.where(created_at: Date.current.all_day).count,
      new_users_this_week: User.where(created_at: Date.current.beginning_of_week..Date.current.end_of_week).count,

      # Post metrics
      total_posts: Post.count,
      active_posts: Post.active.count,
      posts_today: Post.where(created_at: Date.current.all_day).count,

      # Chat metrics
      total_chat_rooms: ChatRoom.count,
      total_messages: Message.count,
      messages_today: Message.where(created_at: Date.current.all_day).count,

      # Translation metrics
      translations_today: AnalyticsEvent.by_type("translation_completed").today.count,
      teencode_translations: AnalyticsEvent.by_type("translation_completed")
                                         .today
                                         .where("properties->>'contains_teencode' = ?", "true")
                                         .count,

      # Report metrics
      total_reports: Report.count,
      pending_reports: Report.pending.count,

      # Event breakdown
      event_counts_today: AnalyticsEvent.event_counts_by_type(Date.current.all_day),
      event_counts_week: AnalyticsEvent.event_counts_by_type(1.week.ago..Time.current),

      # Device breakdown
      device_breakdown: AnalyticsEvent.device_breakdown(1.week.ago..Time.current),

      # Active users
      active_users_today: AnalyticsEvent.unique_users_count(Date.current.all_day),
      active_users_week: AnalyticsEvent.unique_users_count(1.week.ago..Time.current)
    }

    # Recent events for live monitoring
    @recent_events = AnalyticsEvent.recent.includes(:user).limit(50)
  end

  private

  def authenticate_admin!
    redirect_to root_path unless current_user&.admin?
  end
end

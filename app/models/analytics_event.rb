class AnalyticsEvent < ApplicationRecord
  belongs_to :user, optional: true

  validates :event_type, presence: true

  # Scopes for analytics queries
  scope :recent, -> { order(created_at: :desc) }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :today, -> { where(created_at: Date.current.all_day) }
  scope :this_week, -> { where(created_at: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(created_at: Date.current.beginning_of_month..Date.current.end_of_month) }

  # Helper to extract device info
  def device
    request_details["device"] || "unknown"
  end

  def user_agent
    request_details["ua"]
  end

  def ip_address
    request_details["ip"]
  end

  # Analytics queries
  def self.event_counts_by_type(time_range = 1.week.ago..Time.current)
    where(created_at: time_range)
      .group(:event_type)
      .count
      .sort_by { |_, count| -count }
  end

  def self.unique_users_count(time_range = 1.week.ago..Time.current)
    where(created_at: time_range)
      .where.not(user_id: nil)
      .distinct
      .count(:user_id)
  end

  def self.device_breakdown(time_range = 1.week.ago..Time.current)
    where(created_at: time_range)
      .group("request_details->>'device'")
      .count
  end
end
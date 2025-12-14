module Reportable
  extend ActiveSupport::Concern

  included do
    has_many :reports, as: :reported, dependent: :destroy
    
    scope :reported, -> { joins(:reports).where(reports: { status: 'pending' }).distinct }
    scope :not_reported_by, ->(user) {
      left_joins(:reports)
        .where(reports: { id: nil })
        .or(where.not(reports: { reporter_id: user.id }))
        .distinct
    }
  end

  def reported_by?(user)
    reports.exists?(reporter: user)
  end

  def report_count
    reports.count
  end

  def pending_reports_count
    reports.pending.count
  end
end
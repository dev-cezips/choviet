namespace :beta do
  desc "Generate beta test metrics report"
  task metrics: :environment do
    puts "\n" + "="*60
    puts "CHỢI VIỆT BETA TEST METRICS REPORT"
    puts "Generated at: #{Time.current.strftime('%Y-%m-%d %H:%M')}"
    puts "="*60 + "\n"

    # User Metrics
    puts "\n📊 USER METRICS"
    puts "-" * 40
    total_users = User.count
    users_today = User.where(created_at: Date.current.all_day).count
    users_week = User.where(created_at: 1.week.ago..Time.current).count
    users_with_location = User.where.not(latitude: nil).count

    puts "Total Users: #{total_users}"
    puts "New Today: #{users_today}"
    puts "New This Week: #{users_week}"
    puts "With Location Set: #{users_with_location} (#{(users_with_location.to_f / total_users * 100).round}%)"

    # Activation Metrics
    puts "\n🎯 ACTIVATION METRICS (First 72 hours)"
    puts "-" * 40
    new_users = User.where(created_at: 3.days.ago..Time.current)
    activated_users = new_users.joins("LEFT JOIN posts ON posts.user_id = users.id")
                               .joins("LEFT JOIN messages ON messages.sender_id = users.id")
                               .where("posts.id IS NOT NULL OR messages.id IS NOT NULL")
                               .distinct.count

    activation_rate = new_users.count > 0 ? (activated_users.to_f / new_users.count * 100).round : 0
    puts "Recent Signups: #{new_users.count}"
    puts "Activated: #{activated_users} (#{activation_rate}%)"

    # Engagement Metrics
    puts "\n💬 ENGAGEMENT METRICS"
    puts "-" * 40
    posts_today = Post.where(created_at: Date.current.all_day).count
    posts_week = Post.where(created_at: 1.week.ago..Time.current).count
    messages_today = Message.where(created_at: Date.current.all_day).count
    messages_week = Message.where(created_at: 1.week.ago..Time.current).count

    puts "Posts Today: #{posts_today}"
    puts "Posts This Week: #{posts_week}"
    puts "Messages Today: #{messages_today}"
    puts "Messages This Week: #{messages_week}"

    # Translation Metrics
    puts "\n🌐 TRANSLATION METRICS"
    puts "-" * 40
    translations_today = AnalyticsEvent.by_type("translation_completed").today.count
    translations_week = AnalyticsEvent.by_type("translation_completed").this_week.count
    teencode_translations = AnalyticsEvent.by_type("translation_completed")
                                        .where("properties->>'contains_teencode' = ?", "true")
                                        .this_week.count

    teencode_rate = translations_week > 0 ? (teencode_translations.to_f / translations_week * 100).round : 0
    puts "Translations Today: #{translations_today}"
    puts "Translations This Week: #{translations_week}"
    puts "With Teencode: #{teencode_translations} (#{teencode_rate}%)"

    # Trust & Safety Metrics
    puts "\n🛡️ TRUST & SAFETY METRICS"
    puts "-" * 40
    total_reports = Report.count
    pending_reports = Report.pending.count
    resolved_reports = Report.resolved.count
    report_rate = Post.count > 0 ? (total_reports.to_f / Post.count * 100).round(2) : 0

    puts "Total Reports: #{total_reports}"
    puts "Pending Review: #{pending_reports}"
    puts "Resolved: #{resolved_reports}"
    puts "Report Rate: #{report_rate}%"

    # Weekly Active Users
    puts "\n👥 WEEKLY ACTIVE USERS (WAU)"
    puts "-" * 40
    wau = AnalyticsEvent.where(created_at: 1.week.ago..Time.current)
                        .distinct.count(:user_id)
    wau_rate = total_users > 0 ? (wau.to_f / total_users * 100).round : 0

    puts "WAU: #{wau} (#{wau_rate}% of total users)"

    # Post Type Distribution
    puts "\n📝 POST TYPE DISTRIBUTION"
    puts "-" * 40
    Post.post_types.each do |type, _|
      count = Post.where(post_type: type).count
      percentage = Post.count > 0 ? (count.to_f / Post.count * 100).round : 0
      puts "#{type.humanize}: #{count} (#{percentage}%)"
    end

    # Device Distribution
    puts "\n📱 DEVICE DISTRIBUTION (Last 7 days)"
    puts "-" * 40
    device_breakdown = AnalyticsEvent.device_breakdown(1.week.ago..Time.current)
    total_events = device_breakdown.values.sum

    device_breakdown.each do |device, count|
      percentage = total_events > 0 ? (count.to_f / total_events * 100).round : 0
      puts "#{(device || 'Unknown').capitalize}: #{count} (#{percentage}%)"
    end

    # Top Events
    puts "\n⚡ TOP EVENTS (Last 24 hours)"
    puts "-" * 40
    event_counts = AnalyticsEvent.event_counts_by_type(Date.current.all_day)
    event_counts.first(10).each do |event_type, count|
      puts "#{event_type.humanize}: #{count}"
    end

    # Location Distribution
    puts "\n📍 USER LOCATION DISTRIBUTION"
    puts "-" * 40
    Location.joins(:users).group(:name_vi).count.each do |location, count|
      puts "#{location}: #{count} users"
    end

    puts "\n" + "="*60 + "\n"
  end

  desc "Send daily beta metrics email"
  task daily_report: :environment do
    # This would integrate with ActionMailer to send the report
    puts "Daily report would be sent to admins..."
  end

  desc "Export beta metrics to CSV"
  task export_csv: :environment do
    require "csv"

    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    filename = "tmp/beta_metrics_#{timestamp}.csv"

    CSV.open(filename, "wb") do |csv|
      # Headers
      csv << [ "Date", "Total Users", "New Users Today", "WAU", "Posts Today",
              "Messages Today", "Translations Today", "Reports Today" ]

      # Last 30 days data
      30.downto(0) do |days_ago|
        date = days_ago.days.ago.to_date
        day_range = date.all_day

        csv << [
          date.to_s,
          User.where("created_at <= ?", date.end_of_day).count,
          User.where(created_at: day_range).count,
          AnalyticsEvent.where(created_at: date.beginning_of_week..date.end_of_week)
                        .distinct.count(:user_id),
          Post.where(created_at: day_range).count,
          Message.where(created_at: day_range).count,
          AnalyticsEvent.by_type("translation_completed").where(created_at: day_range).count,
          Report.where(created_at: day_range).count
        ]
      end
    end

    puts "Metrics exported to #{filename}"
  end
end

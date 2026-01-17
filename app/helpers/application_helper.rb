module ApplicationHelper
  # Vietnamese time ago helper
  def viet_time_ago(time)
    return "" unless time

    diff_seconds = Time.current - time
    diff_minutes = diff_seconds / 60
    diff_hours = diff_minutes / 60
    diff_days = diff_hours / 24

    case
    when diff_minutes < 1
      "vừa xong"
    when diff_minutes < 60
      "#{diff_minutes.to_i} phút trước"
    when diff_hours < 24
      "#{diff_hours.to_i} giờ trước"
    when diff_days < 7
      "#{diff_days.to_i} ngày trước"
    when diff_days < 30
      "#{(diff_days / 7).to_i} tuần trước"
    else
      time.strftime("%d/%m/%Y")
    end
  end

  # User avatar helper
  def user_avatar(user, size: "w-10 h-10", text_size: "text-sm")
    if user.avatar.attached?
      image_tag user.avatar, class: "#{size} rounded-full object-cover"
    elsif user.avatar_url.present?
      image_tag user.avatar_url, class: "#{size} rounded-full object-cover"
    else
      content_tag :div, class: "#{size} rounded-full bg-gradient-to-br from-zalo-blue to-blue-700 flex items-center justify-center text-white font-semibold #{text_size}" do
        user.display_name.first.upcase
      end
    end
  end

  # Category badge helper
  def category_badge(post)
    colors = {
      "question" => "bg-blue-100 text-blue-800",
      "marketplace" => "bg-green-100 text-green-800",
      "free_talk" => "bg-purple-100 text-purple-800",
      "job" => "bg-orange-100 text-orange-800",
      "housing" => "bg-red-100 text-red-800",
      "service" => "bg-indigo-100 text-indigo-800"
    }

    color_class = colors[post.post_type] || "bg-gray-100 text-gray-800"

    content_tag :span, class: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium #{color_class}" do
      post_type_icon(post) + " " + post_type_label(post)
    end
  end

  # Post type display order
  def post_type_order
    %w[question marketplace free_talk]
  end

  # Post type icon helper - accepts either post object or type string
  def post_type_icon(post_or_type)
    type = if post_or_type.respond_to?(:post_type)
             post_or_type.post_type
    else
             post_or_type.to_s
    end

    icons = {
      "question" => "❓",
      "marketplace" => "🛍️",
      "free_talk" => "💬",
      "job" => "💼",
      "housing" => "🏠",
      "service" => "🔧"
    }
    icons[type] || "📝"
  end

  # Post type label helper - accepts either post object or type string
  def post_type_label(post_or_type)
    type = if post_or_type.respond_to?(:post_type)
             post_or_type.post_type
    else
             post_or_type.to_s
    end

    I18n.t("posts.types.#{type}", default: type.humanize)
  end

  # Post type options for select
  def post_type_options
    post_type_order.map { |type| [ post_type_label(type), type ] }
  end

  # Product condition display order
  def product_condition_order
    %w[new_item like_new good fair poor]
  end

  # Product condition label (i18n)
  def product_condition_label(condition)
    key = condition.to_s
    I18n.t("products.conditions.#{key}", default: key.humanize)
  end

  # Product condition icon
  def product_condition_icon(condition)
    {
      "new_item" => "🆕",
      "like_new" => "✨",
      "good" => "👍",
      "fair" => "🔄",
      "poor" => "⚠️"
    }.fetch(condition.to_s, "🏷️")
  end

  # Product condition badge class
  def product_condition_badge_class(condition)
    {
      "new_item" => "bg-green-100 text-green-800",
      "like_new" => "bg-blue-100 text-blue-800",
      "good" => "bg-yellow-100 text-yellow-800",
      "fair" => "bg-orange-100 text-orange-800",
      "poor" => "bg-red-100 text-red-800"
    }.fetch(condition.to_s, "bg-gray-100 text-gray-800")
  end

  # Product condition options for select
  def product_condition_options
    product_condition_order.map { |c| [ product_condition_label(c), c ] }
  end

  # Product availability label (i18n) - accepts product object or boolean/string
  def product_availability_label(product_or_sold)
    sold = normalize_product_availability(product_or_sold)
    key = sold ? "sold" : "available"
    I18n.t("products.#{key}", default: key.capitalize)
  end

  # Product availability icon
  def product_availability_icon(product_or_sold)
    sold = normalize_product_availability(product_or_sold)
    sold ? "✅" : "🟢"
  end

  # Product availability badge class
  def product_availability_badge_class(product_or_sold)
    sold = normalize_product_availability(product_or_sold)
    sold ? "bg-red-100 text-red-800" : "bg-green-100 text-green-800"
  end

  # Product availability panel classes (container + text)
  def product_availability_panel_classes(product_or_sold)
    sold = normalize_product_availability(product_or_sold)
    status_panel_classes(sold ? :danger : :success)
  end

  # Generic status panel classes for different variants
  def status_panel_classes(variant)
    case variant.to_sym
    when :success
      { container: "bg-green-50 border-green-200", text: "text-green-800" }
    when :danger
      { container: "bg-red-50 border-red-200", text: "text-red-800" }
    when :warning
      { container: "bg-yellow-50 border-yellow-200", text: "text-yellow-800" }
    when :info
      { container: "bg-blue-50 border-blue-200", text: "text-blue-800" }
    else # :neutral
      { container: "bg-gray-50 border-gray-200", text: "text-gray-800" }
    end
  end

  # Post status display order
  def post_status_order
    %w[draft active sold expired deleted]
  end

  # Post status label (i18n) - accepts either post object or status string
  def post_status_label(post_or_status)
    status = normalize_post_status(post_or_status)
    I18n.t("posts.statuses.#{status}", default: status.humanize)
  end

  # Post status icon
  def post_status_icon(post_or_status)
    status = normalize_post_status(post_or_status)
    {
      "draft" => "📝",
      "active" => "🟢",
      "sold" => "✅",
      "expired" => "⏰",
      "deleted" => "🗑️"
    }.fetch(status, "📋")
  end

  # Post status badge class
  def post_status_badge_class(post_or_status)
    status = normalize_post_status(post_or_status)
    {
      "draft" => "bg-yellow-100 text-yellow-800",
      "active" => "bg-green-100 text-green-800",
      "sold" => "bg-purple-100 text-purple-800",
      "expired" => "bg-orange-100 text-orange-800",
      "deleted" => "bg-red-100 text-red-800"
    }.fetch(status, "bg-gray-100 text-gray-800")
  end

  # Post status options for select
  def post_status_options
    post_status_order.map { |s| [ post_status_label(s), s ] }
  end

  # Trade status display order
  def trade_status_order
    %w[negotiating completed cancelled]
  end

  # Trade status label (i18n) - accepts either chat_room object or status string
  def trade_status_label(chat_room_or_status)
    status = normalize_trade_status(chat_room_or_status)
    I18n.t("trade_statuses.#{status}", default: status.humanize)
  end

  # Trade status icon
  def trade_status_icon(chat_room_or_status)
    status = normalize_trade_status(chat_room_or_status)
    {
      "negotiating" => "🟡",
      "completed" => "🟢",
      "cancelled" => "🔴"
    }.fetch(status, "⚪")
  end

  # Trade status badge class
  def trade_status_badge_class(chat_room_or_status)
    status = normalize_trade_status(chat_room_or_status)
    {
      "negotiating" => "bg-yellow-100 text-yellow-800",
      "completed" => "bg-green-100 text-green-800",
      "cancelled" => "bg-red-100 text-red-800"
    }.fetch(status, "bg-gray-100 text-gray-800")
  end

  # Report status display order
  def report_status_order
    %w[pending reviewed resolved dismissed]
  end

  # Report status label (i18n) - accepts either report object or status string
  def report_status_label(report_or_status)
    status = normalize_report_status(report_or_status)
    I18n.t("admin.reports.statuses.#{status}", default: status.humanize)
  end

  # Report status icon
  def report_status_icon(report_or_status)
    status = normalize_report_status(report_or_status)
    {
      "pending" => "🟡",
      "reviewed" => "🔵",
      "resolved" => "🟢",
      "dismissed" => "⚪"
    }.fetch(status, "⚪")
  end

  # Report status badge class
  def report_status_badge_class(report_or_status)
    status = normalize_report_status(report_or_status)
    {
      "pending" => "bg-yellow-100 text-yellow-800",
      "reviewed" => "bg-blue-100 text-blue-800",
      "resolved" => "bg-green-100 text-green-800",
      "dismissed" => "bg-gray-100 text-gray-800"
    }.fetch(status, "bg-gray-100 text-gray-800")
  end

  # Location display helper
  def location_display(location, user = nil)
    return "" unless location

    if current_user&.vietnamese?
      location.name_vi
    else
      "#{location.name_vi} (#{location.name_ko})"
    end
  end

  # Price display helper
  def price_display(price)
    return "" unless price

    price = price.to_i  # Convert to integer

    # Always show full number with delimiter for clarity
    # e.g., 50,000₩ instead of 5만원
    "#{number_with_delimiter(price)}₩"
  end

  # Active link class helper
  def active_link_class(path, base_class = "")
    # For posts path with type parameter
    if path == posts_path
      current = request.path == path && params[:type].blank?
    elsif path.include?("type=")
      type = path.split("type=").last
      current = request.path == posts_path && params[:type] == type
    else
      current = current_page?(path)
    end

    # Use inline styles for active state since custom Tailwind classes aren't compiling
    if current
      # Active state: blue background with white text
      "#{base_class} bg-blue-600 text-white font-semibold"
    else
      # Inactive state: transparent background with gray text
      "#{base_class} bg-transparent text-gray-600 hover:text-blue-600 hover:bg-blue-50"
    end
  end

  # Check if message contains suspicious content
  def suspicious_message?(content)
    return false if content.blank?

    suspicious_patterns = [
      /\b\d{9,}\b/,                    # Account numbers (9+ digits)
      /\bzalo\s*[:：]?\s*\S+/i,        # Zalo IDs
      /\bkakao\s*[:：]?\s*\S+/i,       # KakaoTalk IDs
      /\btelegram\s*[:：]?\s*@?\S+/i,  # Telegram IDs
      /\bviber\s*[:：]?\s*\S+/i,       # Viber IDs
      /chuyển\s+tiền\s+trước/i,        # "transfer money first"
      /gửi\s+tiền\s+trước/i           # "send money first"
    ]

    suspicious_patterns.any? { |pattern| content.match?(pattern) }
  end

  private

  def normalize_post_status(post_or_status)
    post_or_status.respond_to?(:status) ? post_or_status.status.to_s : post_or_status.to_s
  end

  def normalize_trade_status(chat_room_or_status)
    chat_room_or_status.respond_to?(:trade_status) ? chat_room_or_status.trade_status.to_s : chat_room_or_status.to_s
  end

  def normalize_report_status(report_or_status)
    report_or_status.respond_to?(:status) ? report_or_status.status.to_s : report_or_status.to_s
  end

  def normalize_product_availability(product_or_sold)
    return product_or_sold.sold? if product_or_sold.respond_to?(:sold?)

    # Normalize string input
    value = product_or_sold.to_s.strip.downcase
    return true if %w[sold true 1].include?(value)
    return false if %w[available false 0].include?(value) || value.empty?

    # Fallback: truthy check for other values
    !!product_or_sold
  end
end

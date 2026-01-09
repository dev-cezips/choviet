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
end

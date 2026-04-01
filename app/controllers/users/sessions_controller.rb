class Users::SessionsController < Devise::SessionsController
  # Skip the default Devise behavior for failed login
  skip_before_action :verify_signed_out_user, only: :destroy

  def create
    Rails.logger.info "=== LOGIN ATTEMPT ==="
    Rails.logger.info "Email: #{params[:user][:email]}"
    Rails.logger.info "Has password: #{params[:user][:password].present?}"

    super do |resource|
      # Send login notification to other devices if user has push endpoints
      send_login_notification(resource) if resource.persisted?
    end
  end

  protected

  # This is used by Devise to redirect after sign in
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || posts_path
  end

  # This is used by Devise to redirect after sign out
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  def send_login_notification(user)
    # Only send if user has push endpoints (meaning they've logged in before with push)
    return unless user.push_endpoints.active.exists?

    # Get device/browser info for the notification
    device_info = extract_device_info(request.user_agent)

    # Create notification for login alert
    notification = Notification.create!(
      recipient: user,
      actor: user,
      kind: :system_alert,
      title: login_notification_title(user),
      body: login_notification_body(user, device_info)
    )

    # Queue push delivery
    PushDeliveryJob.perform_later(notification.id)

    Rails.logger.info "[LOGIN] Sent login notification to user #{user.id}"
  rescue => e
    # Don't block login if notification fails
    Rails.logger.error "[LOGIN] Failed to send login notification: #{e.message}"
  end

  def extract_device_info(user_agent)
    return "Unknown device" if user_agent.blank?

    # Simple device detection
    if user_agent.include?("iPhone")
      "iPhone"
    elsif user_agent.include?("iPad")
      "iPad"
    elsif user_agent.include?("Android")
      "Android"
    elsif user_agent.include?("Mac")
      "Mac"
    elsif user_agent.include?("Windows")
      "Windows PC"
    else
      "Web browser"
    end
  end

  def login_notification_title(user)
    case user.locale
    when "vi"
      "🔐 Đăng nhập mới"
    when "ko"
      "🔐 새 로그인 감지"
    else
      "🔐 New login detected"
    end
  end

  def login_notification_body(user, device_info)
    time = Time.current.strftime("%H:%M")

    case user.locale
    when "vi"
      "Tài khoản của bạn vừa đăng nhập từ #{device_info} lúc #{time}. Nếu không phải bạn, hãy đổi mật khẩu ngay."
    when "ko"
      "#{device_info}에서 #{time}에 로그인되었습니다. 본인이 아니라면 비밀번호를 변경하세요."
    else
      "Your account was logged in from #{device_info} at #{time}. If this wasn't you, change your password."
    end
  end
end

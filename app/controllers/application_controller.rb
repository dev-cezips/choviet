class ApplicationController < ActionController::Base
  include Trackable

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Include helpers
  helper MoneyHelper

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  private

  def set_locale
    I18n.locale = :vi   # 강제 베트남어 - No Korean Stress 원칙
    Rails.logger.debug "=== LOCALE SET TO: #{I18n.locale} ==="
  end

  def change_locale
    if params[:locale].present?
      session[:locale] = params[:locale]
      redirect_back(fallback_location: root_path)
    end
  end

  def extract_locale
    parsed_locale = params[:locale] ||
                   session[:locale] ||
                   (current_user.locale if user_signed_in?) ||
                   extract_locale_from_accept_language_header ||
                   "vi"

    I18n.available_locales.map(&:to_s).include?(parsed_locale) ? parsed_locale : "vi"
  end

  def extract_locale_from_accept_language_header
    request.env["HTTP_ACCEPT_LANGUAGE"]&.scan(/^[a-z]{2}/)&.first
  end

  def default_url_options
    {}  # No locale in URLs since we force Vietnamese
  end

  def after_sign_in_path_for(resource)
    # If user was trying to access a specific page before login, go there
    # Otherwise, go to marketplace listing page
    stored_location_for(resource) || marketplace_path
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :phone, :locale, :location_code ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :phone, :bio, :locale, :location_code, :avatar_url ])
  end
end

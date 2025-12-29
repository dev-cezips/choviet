class ApplicationController < ActionController::Base
  include Trackable

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Include helpers
  helper MoneyHelper

  before_action :set_locale
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Explicit whitelist (policy): keep this small & clear
  SUPPORTED_LOCALES = %i[vi ko en].freeze

  private

  def set_locale
    I18n.locale = extract_locale
    Rails.logger.debug "=== LOCALE SET TO: #{I18n.locale} ==="
  end

  def change_locale
    locale = normalize_locale(params[:locale])
    unless supported_locale?(locale)
      return respond_to do |format|
        format.html { redirect_back(fallback_location: root_path) }
        format.json { render json: { error: "unsupported_locale" }, status: :unprocessable_entity }
      end
    end

    session[:locale] = locale.to_s
    I18n.locale = locale
    Rails.logger.debug "=== LOCALE CHANGED TO: #{I18n.locale} ==="

    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path) }
      format.json { render json: { locale: I18n.locale }, status: :ok }
    end
  end

  def extract_locale
    candidate = params[:locale] ||
                session[:locale] ||
                (current_user&.locale if user_signed_in?) ||
                extract_locale_from_accept_language_header ||
                I18n.default_locale

    locale = normalize_locale(candidate)
    supported_locale?(locale) ? locale : I18n.default_locale
  end

  # "ko-KR", "vi-VN", "EN" -> :ko, :vi, :en
  def normalize_locale(value)
    s = value.to_s.downcase.strip
    return nil if s.empty?
    s[0, 2].to_sym
  end

  def supported_locale?(locale)
    locale.present? && SUPPORTED_LOCALES.include?(locale) && I18n.available_locales.include?(locale)
  end

  def extract_locale_from_accept_language_header
    header = request.env["HTTP_ACCEPT_LANGUAGE"].to_s
    # Take first locale preference: "ko-KR,ko;q=0.9,en;q=0.8" -> "ko"
    first = header.split(",").first.to_s
    first[/\A([a-z]{2})/i, 1]&.downcase
  end

  def default_url_options
    {}  # No locale in URLs since we force Vietnamese
  end

  public :change_locale

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

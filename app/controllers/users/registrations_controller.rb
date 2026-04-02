class Users::RegistrationsController < Devise::RegistrationsController
  include Trackable
  before_action :configure_permitted_parameters

  def create
    super do |resource|
      if resource.persisted?
        track_event("user_signup", {
          user_id: resource.id,
          locale: resource.locale,
          has_location: resource.location_code.present?
        })
      end
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :locale, :location_code ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :locale, :location_code ])
  end

  def after_sign_up_path_for(resource)
    if resource.needs_onboarding?
      onboarding_path
    else
      super
    end
  end
end

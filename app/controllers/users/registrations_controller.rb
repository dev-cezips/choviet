# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
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
      devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :locale ])
      devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :locale ])
    end

    def after_sign_up_path_for(_resource)
      root_path
    end

    def after_inactive_sign_up_path_for(_resource)
      root_path
    end
  end
end

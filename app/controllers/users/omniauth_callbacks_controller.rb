# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [ :google_oauth2, :apple, :kakao, :failure ]

  def google_oauth2
    handle_auth("Google")
  end

  def apple
    handle_auth("Apple")
  end

  def kakao
    handle_auth("Kakao")
  end

  def failure
    redirect_to root_path, alert: t("devise.omniauth_callbacks.failure", kind: "OAuth", reason: "authentication failed")
  end

  private

  def handle_auth(kind)
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      flash[:notice] = I18n.t("devise.omniauth_callbacks.success", kind: kind)
      sign_in @user, event: :authentication

      if @user.needs_onboarding?
        redirect_to onboarding_path
      else
        redirect_to after_sign_in_path_for(@user)
      end
    else
      session["devise.#{kind.downcase}_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end
end

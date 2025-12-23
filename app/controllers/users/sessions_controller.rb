class Users::SessionsController < Devise::SessionsController
  # Skip the default Devise behavior for failed login
  skip_before_action :verify_signed_out_user, only: :destroy

  def create
    Rails.logger.info "=== LOGIN ATTEMPT ==="
    Rails.logger.info "Email: #{params[:user][:email]}"
    Rails.logger.info "Has password: #{params[:user][:password].present?}"
    super
  end

  protected

  # This is used by Devise to redirect after sign in
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || marketplace_path
  end

  # This is used by Devise to redirect after sign out
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end

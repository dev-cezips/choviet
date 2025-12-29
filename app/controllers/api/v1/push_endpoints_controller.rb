class Api::V1::PushEndpointsController < ApplicationController
  before_action :authenticate_user!
  protect_from_forgery with: :null_session

  def create
    # Find or create endpoint
    ep = current_user.push_endpoints.find_or_initialize_by(
      platform: params.require(:platform),
      device_id: params[:device_id]
    )
    # Update token and activate
    ep.token = params.require(:token)
    ep.active = true
    ep.last_seen_at = Time.current

    if ep.save
      render json: {
        success: true,
        endpoint_id: ep.id,
        message: "Push endpoint registered successfully"
      }
    else
      render json: {
        success: false,
        errors: ep.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    ep = current_user.push_endpoints.find_by!(
      platform: params.require(:platform),
      token: params.require(:token)
    )

    ep.update!(active: false)

    render json: {
      success: true,
      message: "Push endpoint unregistered successfully"
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: "Push endpoint not found"
    }, status: :not_found
  end
end

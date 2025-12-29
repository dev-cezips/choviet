class PushEndpointsController < ApplicationController
  before_action :authenticate_user!

  def create
    # Find or initialize endpoint
    endpoint = current_user.push_endpoints.find_or_initialize_by(
      platform: endpoint_params[:platform],
      token: endpoint_params[:token]
    )

    # Update endpoint details
    endpoint.assign_attributes(
      device_id: endpoint_params[:device_id],
      endpoint_url: endpoint_params[:endpoint_url],
      keys: endpoint_params[:keys],
      active: true,
      last_seen_at: Time.current
    )

    if endpoint.save
      render json: {
        success: true,
        endpoint_id: endpoint.id,
        message: success_message
      }, status: :ok
    else
      render json: {
        success: false,
        errors: endpoint.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    endpoint = current_user.push_endpoints.find(params[:id])

    endpoint.update!(active: false)

    render json: {
      success: true,
      message: unsubscribe_message
    }, status: :ok
  end

  private

  def endpoint_params
    params.require(:push_endpoint).permit(
      :platform,
      :token,
      :device_id,
      :endpoint_url,
      keys: [ :auth, :p256dh ]
    )
  end

  def success_message
    if current_user.vietnamese?
      "Đã đăng ký nhận thông báo"
    else
      "알림 수신 등록 완료"
    end
  end

  def unsubscribe_message
    if current_user.vietnamese?
      "Đã hủy đăng ký thông báo"
    else
      "알림 수신 해제 완료"
    end
  end
end

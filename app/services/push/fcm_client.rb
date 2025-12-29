require "net/http"
require "json"

module Push
  class FcmClient < Client
    FCM_ENDPOINT = "https://fcm.googleapis.com/v1/projects/%{project_id}/messages:send"

    def initialize
      @project_id = ENV.fetch("FCM_PROJECT_ID")
      @access_token = GoogleServiceAccountToken.fetch
    end

    def deliver!(endpoint:, title:, body:, data: {})
      token = endpoint.token
      
      uri = URI(FCM_ENDPOINT % { project_id: @project_id })
      req = Net::HTTP::Post.new(uri)
      req["Authorization"] = "Bearer #{@access_token}"
      req["Content-Type"] = "application/json"

      payload = {
        message: {
          token: token,
          notification: { 
            title: title, 
            body: body 
          },
          data: stringify_hash(data),
          android: {
            priority: "high",
            notification: {
              sound: "default",
              click_action: "OPEN_CONVERSATION"
            }
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
                badge: 1
              }
            }
          }
        }
      }

      req.body = JSON.generate(payload)

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        res = http.request(req)
        unless res.is_a?(Net::HTTPSuccess)
          Rails.logger.error "[FCM] Error: #{res.code} #{res.body}"
          raise "FCM error: #{res.code} #{res.body}"
        end
      end

      true
    end

    private

    def stringify_hash(h)
      (h || {}).transform_values { |v| v.to_s }
    end
  end
end
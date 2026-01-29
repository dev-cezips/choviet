class WellKnownController < ApplicationController
  skip_before_action :verify_authenticity_token

  def apple_app_site_association
    render json: aasa_content, content_type: "application/json"
  end

  private

  def aasa_content
    {
      applinks: {
        apps: [],
        details: [
          {
            appID: "#{ENV.fetch('APPLE_TEAM_ID', 'TEAM_ID')}.cezips.choviet",
            paths: [
              "/posts/*",
              "/users/*",
              "/me",
              "/chat_rooms/*",
              "/conversations/*"
            ]
          }
        ]
      },
      webcredentials: {
        apps: [
          "#{ENV.fetch('APPLE_TEAM_ID', 'TEAM_ID')}.cezips.choviet"
        ]
      }
    }
  end
end

# frozen_string_literal: true

# Middleware to fix Apple Sign In Origin header issue
# Apple sends POST callback from appleid.apple.com, which triggers Rails CSRF Origin check
# This middleware removes the Origin header for Apple callback to bypass the check
module Middleware
  class AppleOriginFix
    def initialize(app)
      @app = app
    end

    def call(env)
      # Remove Origin header for Apple OAuth callback
      if env["PATH_INFO"] == "/users/auth/apple/callback" && env["HTTP_ORIGIN"] == "https://appleid.apple.com"
        env.delete("HTTP_ORIGIN")
      end

      @app.call(env)
    end
  end
end

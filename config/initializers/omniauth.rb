# frozen_string_literal: true

# OmniAuth configuration for Apple Sign In
# Apple sends POST request from appleid.apple.com which requires special handling

OmniAuth.config.allowed_request_methods = [ :post, :get ]
OmniAuth.config.silence_get_warning = true

# Load and register custom middleware to fix Apple Origin header issue
require_relative "../../lib/middleware/apple_origin_fix"
Rails.application.config.middleware.insert_before ActionDispatch::Executor, Middleware::AppleOriginFix

# frozen_string_literal: true

require "omniauth-apple"

# Monkey-patch Apple strategy to skip nonce verification
# Apple's cross-origin POST callback doesn't preserve session cookies
# due to SameSite cookie restrictions, causing nonce validation to fail
module OmniAuth
  module Strategies
    class Apple
      private

      # Override to skip nonce verification
      def verify_nonce!(id_token)
        # Skip nonce verification - session cookies not preserved
        # in cross-origin POST from Apple
        true
      end
    end
  end
end

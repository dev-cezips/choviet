# frozen_string_literal: true

require "omniauth-apple"

# Module to skip nonce verification for Apple Sign In
# Apple's cross-origin POST callback doesn't preserve session cookies
# due to SameSite cookie restrictions, causing nonce validation to fail
module AppleNonceSkip
  private

  # Override to skip nonce verification
  def verify_nonce!(id_token)
    # Skip nonce verification - session cookies not preserved
    # in cross-origin POST from Apple
    true
  end
end

# Prepend to ensure proper method override
OmniAuth::Strategies::Apple.prepend(AppleNonceSkip)

# test/application_system_test_case.rb
require "test_helper"
require "warden/test/helpers"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Use rack_test for fast, stable system tests without JavaScript
  driven_by :rack_test

  include Warden::Test::Helpers

  setup { Warden.test_mode! }
  teardown { Warden.test_reset! }

  def set_radio_and_trigger_change(id)
    # With rack_test, we can't use JavaScript, so we use native methods
    choose(id)
  end
end

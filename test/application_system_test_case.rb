# test/application_system_test_case.rb
require "test_helper"
require "warden/test/helpers"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  if ENV["CI"]
    # CI: Use chromium instead of chrome
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900] do |options|
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--disable-gpu")
      options.add_argument("--headless")
      # Point to chromium binary in CI
      options.binary = "/usr/bin/chromium-browser" if File.exist?("/usr/bin/chromium-browser")
    end
  else
    # Local: Use regular Chrome
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900] do |options|
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
    end
  end

  include Warden::Test::Helpers

  setup { Warden.test_mode! }
  teardown { Warden.test_reset! }

  def set_radio_and_trigger_change(id)
    page.execute_script(<<~JS, id)
      const id = arguments[0];
      const el = document.getElementById(id);
      if (!el) throw new Error("Radio not found: " + id);
      el.checked = true;
      el.dispatchEvent(new Event("change", { bubbles: true }));
    JS
  end
end

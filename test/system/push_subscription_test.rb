require "application_system_test_case"

class PushSubscriptionTest < ApplicationSystemTestCase
  setup do
    @user = users(:basic_user)
    login_as @user, scope: :user
  end

  test "user can manage push notification settings" do
    visit edit_profile_path

    # Should see notification settings (in English for basic_user with 'en' locale)
    assert_text "Notification Settings"

    # Get initial state before making changes
    push_checkbox = find("input[name='user[notification_push_enabled]']")
    original_state = push_checkbox.checked?

    # Toggle it off if it's on, or on if it's off
    if original_state
      uncheck "Push Notifications"
    else
      check "Push Notifications"
    end

    click_button "Save"

    # Wait for redirect to user profile page
    assert_current_path user_path(@user)
    assert_text "Profile updated successfully!" # English success message

    # Verify the change was saved
    @user.reload
    current_state = @user.notification_push_enabled?

    # The state should have changed
    assert_not_equal original_state, current_state
  end

  test "push subscription button shows correct state" do
    skip "Requires JavaScript testing setup"

    # This would test the JavaScript push subscription flow
    # Need Selenium with a browser that supports service workers
  end
end

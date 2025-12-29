require "application_system_test_case"

class PushSubscriptionTest < ApplicationSystemTestCase
  setup do
    @user = users(:basic_user)
    sign_in_as @user
  end
  
  test "user can manage push notification settings" do
    visit edit_profile_path
    
    # Should see notification settings
    assert_text "알림 설정" # Korean since @user has locale: en (defaults to ko)
    
    # Toggle push notifications
    uncheck "푸시 알림"
    click_button "저장"
    
    @user.reload
    assert_not @user.notification_push_enabled?
    
    # Re-enable
    visit edit_profile_path
    check "푸시 알림"
    click_button "저장"
    
    @user.reload
    assert @user.notification_push_enabled?
  end
  
  test "push subscription button shows correct state" do
    skip "Requires JavaScript testing setup"
    
    # This would test the JavaScript push subscription flow
    # Need Selenium with a browser that supports service workers
  end
  
  private
  
  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Đăng nhập"
  end
end
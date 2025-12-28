require "application_system_test_case"

class TrustSafetySystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:basic_user)
    @other_user = users(:vietnamese_user)
    @admin = users(:admin_user)
    @conversation = conversations(:user_conversation)
    
    # Create a post for testing
    @post = @other_user.posts.create!(
      title: "Test Product",
      content: "This is a test product for sale",
      price: 100000,
      location_code: "seoul",
      post_type: "marketplace",
      status: "active"
    )
  end

  test "user can block another user from their profile" do
    sign_in_as @user
    
    # Visit other user's profile
    visit user_path(@other_user)
    
    # Click block button
    assert_text "Nguyễn Văn A"
    click_button "차단" # Korean UI as @user has locale: en (defaults to ko)
    
    # Confirm in dialog
    accept_confirm
    
    # Should see unblock button now
    assert_text "차단 해제"
    assert @user.reload.blocking?(@other_user)
  end

  test "blocked users cannot send messages" do
    # Create a block first
    @user.blocks_given.create!(blocked: @other_user)
    
    sign_in_as @other_user
    
    # Try to DM from a post
    visit post_path(@user.posts.first)
    click_link "Nhắn tin" # Vietnamese UI
    
    # Should be redirected with error
    assert_text "Bạn không thể trò chuyện với người dùng đã bị chặn"
  end

  test "user can report a message in conversation" do
    # Create a message to report
    message = @conversation.conversation_messages.create!(
      user: @other_user,
      body: "This is spam message!"
    )
    
    sign_in_as @user
    
    # Visit conversation
    visit conversation_path(@conversation)
    assert_text "This is spam message!"
    
    # Click report link
    click_link "신고"
    
    # Fill report form in modal
    within "#report_modal" do
      choose "스팸 / 광고"
      fill_in "상세 내용", with: "This user is sending spam"
      click_button "신고하기"
    end
    
    # Should see success message
    assert_text "신고해 주셔서 감사합니다"
    
    # Verify report was created
    assert Report.exists?(
      reporter: @user,
      reportable: message,
      category: "spam"
    )
  end

  test "admin can moderate reports" do
    # Create a report
    report = Report.create!(
      reporter: @user,
      reportable: @post,
      category: "fraud",
      reason: "This looks like a scam",
      status: "pending"
    )
    
    sign_in_as @admin
    
    # Visit admin reports page
    visit admin_reports_path
    
    # Should see the report
    assert_text "Quản lý báo cáo"
    assert_text "fraud"
    assert_text "Basic User"
    
    # Click to view report details
    click_link "Xem"
    
    # Should see report details
    assert_text "Chi tiết báo cáo ##{report.id}"
    assert_text "This looks like a scam"
    assert_text "Test Product"
    
    # Resolve the report
    fill_in "Ghi chú", with: "Verified as fraudulent listing"
    check "Ẩn nội dung"
    click_button "Xử lý báo cáo"
    
    # Should redirect back to list
    assert_text "Đã xử lý báo cáo thành công"
    assert_current_path admin_reports_path
    
    # Verify report was handled
    report.reload
    assert_equal "resolved", report.status
    assert_equal "Verified as fraudulent listing", report.admin_note
  end

  test "rate limit warning appears when approaching limit" do
    skip "Rate limit testing requires special setup"
    
    sign_in_as @user
    visit conversation_path(@conversation)
    
    # Send many messages quickly
    25.times do |i|
      fill_in "conversation_message[body]", with: "Message #{i}"
      click_button "Send"
      sleep 0.1 # Small delay to avoid overwhelming the test
    end
    
    # Should see rate limit warning
    assert_selector ".bg-yellow-50", text: "속도 제한 경고"
  end

  test "block button updates without page reload" do
    sign_in_as @user
    visit user_path(@other_user)
    
    # Initial state - should see block button
    assert_button "차단"
    
    # Click block
    click_button "차단"
    accept_confirm
    
    # Should update to unblock without reload
    assert_no_button "차단"
    assert_button "차단 해제"
    
    # Click unblock
    click_button "차단 해제"
    
    # Should update back to block
    assert_button "차단"
    assert_no_button "차단 해제"
  end

  test "admin can batch process reports" do
    # Create multiple reports
    3.times do |i|
      Report.create!(
        reporter: @user,
        reportable: @post,
        category: "spam",
        reason: "Spam #{i}",
        status: "pending"
      )
    end
    
    sign_in_as @admin
    visit admin_reports_path
    
    # Select all reports
    check "select-all"
    
    # Choose batch action
    select "Bác bỏ", from: "batch_action"
    
    # Should process all reports
    assert_text "Đã bác bỏ 3 báo cáo"
    
    # Verify all are dismissed
    Report.all.each do |report|
      assert_equal "dismissed", report.status
    end
  end

  private

  def sign_in_as(user)
    visit new_user_session_path
    fill_in "Email", with: user.email
    fill_in "Password", with: "password123"
    click_button "Đăng nhập"
  end
end
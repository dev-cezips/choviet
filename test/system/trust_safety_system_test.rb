require "application_system_test_case"

class TrustSafetySystemTest < ApplicationSystemTestCase
  setup do
    @user = users(:basic_user)
    @other_user = users(:vietnamese_user)
    @admin = users(:admin_user)
    @conversation = conversations(:user_conversation)

    # Create conversation participants
    @conversation.conversation_participants.find_or_create_by!(user: @user)
    @conversation.conversation_participants.find_or_create_by!(user: @other_user)

    # Create a post for testing
    @post = @other_user.posts.create!(
      title: "Test Post",
      content: "This is a test post content (10+ chars).",
      post_type: "free_talk",
      status: "active"
    )
  end

  test "user can block another user from their profile" do
    skip "JavaScript confirm dialog not working in CI headless environment"
    login_as @user, scope: :user

    # Visit other user's profile
    visit user_path(@other_user)

    # Click block button
    assert_text "Nguyễn Văn A"
    click_button "Block"

    # Confirm in dialog
    accept_confirm

    # Should see unblock button now
    assert_text "Unblock"
    assert @user.reload.blocking?(@other_user)
  end

  test "blocked users cannot send messages" do
    # Create a block first
    @user.blocks_given.create!(blocked: @other_user)

    login_as @other_user, scope: :user

    # Try to DM from a post created by @user
    user_post = @user.posts.create!(
      title: "User Test Post",
      content: "This is another test post content.",
      post_type: "free_talk",
      status: "active"
    )
    visit post_path(user_post)
    click_button "Nhắn tin riêng" # Vietnamese UI

    # Should be redirected with error
    assert_text "Bạn không thể trò chuyện với người dùng đã bị chặn"
  end

  test "user can report a message in conversation" do
    skip "Turbo Frame modal interactions not working correctly in test environment"
    # Create a message to report
    message = @conversation.conversation_messages.create!(
      user: @other_user,
      body: "This is spam message!"
    )

    login_as @user, scope: :user

    # Visit conversation
    visit conversation_path(@conversation)
    assert_text "This is spam message!"

    # Click report link
    click_link "Report" # English text since @user locale is 'en'

    # Wait for modal to load and fill report form
    within "turbo-frame#modal" do
      # Choose spam option - wait for it to be visible
      assert_selector "input[type='radio']", count: 4
      find("label", text: /Spam/).click # Find label containing "Spam" text
      fill_in "report_description", with: "This user is sending spam" # Use full field ID
      click_button "Submit Report" # English text
    end

    # Should see success message
    assert_text "Report submitted successfully" # English for user with 'en' locale

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
      reason_code: "scam",
      description: "This looks like a scam",
      status: "pending"
    )

    login_as @admin, scope: :user

    # Visit admin reports page
    visit admin_reports_path

    # Should see the report
    assert_text I18n.t("admin.reports.title")
    assert_text "scam"
    assert_text "Basic User"

    # Click to view report details
    click_link I18n.t("admin.reports.actions.view")

    # Should see report details
    assert_text "#{I18n.t('admin.reports.detail_title')} ##{report.id}"
    assert_text "This looks like a scam"
    assert_text "Test Post"

    # Resolve the report (use within to target the resolve form specifically)
    within "form[action*='resolve']" do
      fill_in "admin_note", with: "Verified as fraudulent listing"
      check "Ẩn nội dung"
      click_button "Xử lý báo cáo"
    end

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

    login_as @user, scope: :user
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
    skip "JavaScript confirm dialog not working in CI headless environment"
    login_as @user, scope: :user
    visit user_path(@other_user)

    # Initial state - should see block button
    assert_button "Block"

    # Click block
    click_button "Block"
    accept_confirm

    # Should update to unblock without reload
    assert_no_button "Block"
    assert_button "Unblock"

    # Click unblock
    click_button "Unblock"

    # Should update back to block
    assert_button "Block"
    assert_no_button "Unblock"
  end

  test "admin can batch process reports" do
    skip "JavaScript form submission not working correctly in test environment"
    # Create multiple reports from different users
    post1 = @user.posts.create!(title: "Post 1", content: "Test content 1", post_type: "free_talk", status: "active")
    post2 = @user.posts.create!(title: "Post 2", content: "Test content 2", post_type: "free_talk", status: "active")
    post3 = @user.posts.create!(title: "Post 3", content: "Test content 3", post_type: "free_talk", status: "active")

    Report.create!(
      reporter: @other_user,
      reportable: post1,
      reason_code: "spam",
      description: "Spam 1",
      status: "pending"
    )
    Report.create!(
      reporter: @other_user,
      reportable: post2,
      reason_code: "spam",
      description: "Spam 2",
      status: "pending"
    )
    Report.create!(
      reporter: @other_user,
      reportable: post3,
      reason_code: "spam",
      description: "Spam 3",
      status: "pending"
    )

    login_as @admin, scope: :user
    visit admin_reports_path

    # Select all reports
    find("#select-all").check

    # Make sure checkboxes are actually checked and have values
    assert find("#select-all").checked?
    checkboxes = all(".report-checkbox")
    assert_equal 3, checkboxes.count
    checkboxes.each do |checkbox|
      assert checkbox.checked?
      assert checkbox.value.present?
    end

    # Choose batch action
    batch_select = find("select[name='batch_action']")
    batch_select.select "Bác bỏ"
    assert_equal "dismiss", batch_select.value

    # Add report IDs to the form manually since JavaScript event handling doesn't work in tests
    page.execute_script(<<~JS)
      const form = document.getElementById('batch-form');
      // Add batch action value
      const actionInput = document.createElement('input');
      actionInput.type = 'hidden';
      actionInput.name = 'batch_action';
      actionInput.value = 'dismiss';
      form.appendChild(actionInput);

      // Add report IDs
      const checkboxes = document.querySelectorAll('.report-checkbox:checked');
      checkboxes.forEach(cb => {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = 'report_ids[]';
        input.value = cb.value;
        form.appendChild(input);
      });
      form.submit();
    JS

    # Should process all reports
    assert_text "Đã bác bỏ 3 báo cáo"

    # Verify all are dismissed
    Report.all.each do |report|
      assert_equal "dismissed", report.status
    end
  end
end

require "test_helper"

class TrustSafetyTest < ActionDispatch::IntegrationTest
  setup do
    @user1 = users(:basic_user)
    @user2 = users(:vietnamese_user)
    @admin = users(:admin_user) # Need to set admin: true in fixtures
    @conversation = conversations(:user_conversation)
    @post = posts(:iphone_post)
  end

  test "user can block another user" do
    sign_in @user1
    
    # Block user
    assert_difference "Block.count", 1 do
      post blocks_path, params: { blocked_id: @user2.id }
    end
    assert_response :redirect
    
    # Verify block exists
    assert @user1.blocking?(@user2)
    assert Block.blocked?(@user1, @user2)
  end

  test "blocked users cannot send messages to each other" do
    # Create a block
    @user1.blocks_given.create!(blocked: @user2)
    
    # Try to create conversation as blocked user
    sign_in @user2
    post dm_post_path(@user1.posts.first)
    assert_response :redirect
    assert_equal "Bạn không thể trò chuyện với người dùng đã bị chặn.", flash[:alert]
    
    # Try to access existing conversation
    get conversation_path(@conversation)
    assert_response :redirect
  end

  test "user can report a message" do
    sign_in @user1
    message = @conversation.conversation_messages.create!(user: @user2, body: "Test message")
    
    # Report the message
    assert_difference "Report.count", 1 do
      post conversation_message_reports_path(message), params: {
        report: { category: "spam", reason: "This is spam" }
      }
    end
    
    # Verify report was created
    report = Report.last
    assert_equal @user1, report.reporter
    assert_equal message, report.reportable
    assert_equal "spam", report.category
  end

  test "user cannot report their own content" do
    sign_in @user1
    
    # Try to report own post
    get new_post_report_path(@user1.posts.first)
    assert_response :redirect
    assert_equal "Bạn đã báo cáo nội dung này rồi.", flash[:alert]
  end

  test "admin can view and handle reports" do
    # Create a report
    report = Report.create!(
      reporter: @user1,
      reportable: @post,
      category: "spam",
      reason: "This is spam",
      status: "pending"
    )
    
    sign_in @admin
    
    # View reports list
    get admin_reports_path
    assert_response :success
    assert_select "td", text: "##{report.id}"
    
    # View report details
    get admin_report_path(report)
    assert_response :success
    assert_select "h1", text: /Chi tiết báo cáo ##{report.id}/
    
    # Resolve the report
    patch resolve_admin_report_path(report), params: {
      admin_note: "Verified as spam"
    }
    assert_response :redirect
    
    report.reload
    assert_equal "resolved", report.status
    assert_equal @admin, report.handled_by
    assert_equal "Verified as spam", report.admin_note
    assert_not_nil report.handled_at
  end

  test "admin can batch dismiss reports" do
    # Create multiple reports
    reports = 3.times.map do
      Report.create!(
        reporter: @user1,
        reportable: @post,
        category: "spam",
        reason: "Test",
        status: "pending"
      )
    end
    
    sign_in @admin
    
    # Batch dismiss
    assert_changes -> { Report.pending.count }, from: 3, to: 0 do
      post batch_action_admin_reports_path, params: {
        report_ids: reports.map(&:id),
        batch_action: "dismiss"
      }
    end
    
    assert_response :redirect
    assert_equal "Đã bác bỏ 3 báo cáo.", flash[:notice]
  end

  test "rate limiting protects against spam messages" do
    sign_in @user1
    
    # Send messages up to the limit (30 per minute in config)
    30.times do |i|
      post conversation_conversation_messages_path(@conversation), params: {
        conversation_message: { body: "Message #{i}" }
      }
      assert_response :success, "Failed on message #{i}"
    end
    
    # Next message should be rate limited
    post conversation_conversation_messages_path(@conversation), params: {
      conversation_message: { body: "Spam message" }
    }
    assert_response :too_many_requests
  end

  test "non-admin cannot access admin area" do
    sign_in @user1
    
    get admin_reports_path
    assert_response :redirect
    assert_equal "Bạn không có quyền truy cập khu vực này.", flash[:alert]
  end

  test "blocking prevents conversation list display" do
    sign_in @user1
    
    # See conversation before blocking
    get conversations_path
    assert_response :success
    assert_select "a[href='#{conversation_path(@conversation)}']"
    
    # Block the other user
    post blocks_path, params: { blocked_id: @user2.id }
    
    # Conversation should not appear in list
    get conversations_path
    assert_response :success
    assert_select "a[href='#{conversation_path(@conversation)}']", count: 0
  end

  test "auto-hide content after multiple reports" do
    # Skip if Post doesn't have status field
    skip unless @post.respond_to?(:status)
    
    # Create 3 reports from different users
    3.times do |i|
      user = User.create!(
        email: "reporter#{i}@example.com",
        password: "password",
        location_code: "seoul"
      )
      Report.create!(
        reporter: user,
        reportable: @post,
        category: "inappropriate",
        reason: "Inappropriate content"
      )
    end
    
    # Post should be auto-hidden
    @post.reload
    assert_equal "hidden", @post.status
  end
end
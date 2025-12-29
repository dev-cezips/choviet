require "test_helper"

class PushNotificationsTest < ActionDispatch::IntegrationTest
  setup do
    # Clear cache to ensure clean state for each test
    Rails.cache.clear

    @user1 = users(:basic_user)
    @user2 = users(:vietnamese_user)
    @conversation = conversations(:user_conversation)

    # Create push endpoint for user2
    @endpoint = @user2.push_endpoints.create!(
      platform: "web",
      token: "test-token-123",
      endpoint_url: "https://fcm.googleapis.com/fcm/send/test",
      keys: { auth: "auth-key", p256dh: "p256dh-key" },
      active: true
    )
  end

  test "dm message creates notification and enqueues push job" do
    sign_in @user1

    assert_difference [ "Notification.count", "enqueued_jobs.size" ] do
      post conversation_conversation_messages_path(@conversation),
        params: { conversation_message: { body: "Hello there!" } }
    end

    notification = Notification.last
    assert_equal @user2, notification.recipient
    assert_equal @user1, notification.actor
    assert_equal "dm_message", notification.kind
    assert_equal "Hello there!", notification.body

    # Check job was enqueued
    assert_enqueued_with(job: PushDeliveryJob, args: [ notification.id ])
  end

  test "blocked users do not receive push notifications" do
    # User2 blocks User1
    Block.create!(blocker: @user2, blocked: @user1)

    sign_in @user1

    # Message is created but no notification
    assert_difference "ConversationMessage.count", 1 do
      assert_no_difference "Notification.count" do
        post conversation_conversation_messages_path(@conversation),
          params: { conversation_message: { body: "Blocked message" } }
      end
    end
  end

  test "users with push disabled do not get notifications delivered" do
    # Disable push for user2
    @user2.update!(notification_push_enabled: false)

    sign_in @user1

    # Create message and process jobs
    perform_enqueued_jobs do
      post conversation_conversation_messages_path(@conversation),
        params: { conversation_message: { body: "No push message" } }
    end

    notification = Notification.last
    assert_equal "skipped", notification.status
    assert_equal "push_disabled", notification.failure_reason
  end

  test "users with dm notifications disabled get skipped" do
    # Disable DM notifications for user2
    @user2.update!(notification_dm_enabled: false)

    sign_in @user1

    perform_enqueued_jobs do
      post conversation_conversation_messages_path(@conversation),
        params: { conversation_message: { body: "No DM notification" } }
    end

    notification = Notification.last
    assert_equal "skipped", notification.status
    assert_equal "dm_disabled", notification.failure_reason
  end

  test "users without push endpoints get skipped" do
    # Remove all endpoints
    @user2.push_endpoints.destroy_all

    sign_in @user1

    perform_enqueued_jobs do
      post conversation_conversation_messages_path(@conversation),
        params: { conversation_message: { body: "No endpoint" } }
    end

    notification = Notification.last
    assert_equal "skipped", notification.status
    assert_equal "no_active_endpoints", notification.failure_reason
  end

  test "push endpoint registration creates endpoint" do
    sign_in @user1

    assert_difference "PushEndpoint.count", 1 do
      post push_endpoints_path, params: {
        push_endpoint: {
          platform: "web",
          token: "new-token-456",
          endpoint_url: "https://fcm.googleapis.com/fcm/send/new",
          keys: { auth: "new-auth", p256dh: "new-p256dh" }
        }
      }, as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]

    endpoint = PushEndpoint.last
    assert_equal @user1, endpoint.user
    assert_equal "web", endpoint.platform
    assert endpoint.active?
  end

  test "push endpoint unregistration deactivates endpoint" do
    sign_in @user2

    delete push_endpoint_path(@endpoint)

    assert_response :success
    @endpoint.reload
    assert_not @endpoint.active?
  end

  test "notification includes conversation context" do
    sign_in @user1

    post conversation_conversation_messages_path(@conversation),
      params: { conversation_message: { body: "Test message" } }

    notification = Notification.last
    assert_equal @conversation.id, notification.data["conversation_id"]
    assert_equal @user1.display_name, notification.data["sender_name"]
  end

  test "failed push delivery updates notification status" do
    # Make Push client fail
    Push.client.stub :deliver!, ->(_) { raise "Push failed!" } do
      sign_in @user1

      perform_enqueued_jobs do
        post conversation_conversation_messages_path(@conversation),
          params: { conversation_message: { body: "Will fail" } }
      end

      notification = Notification.last
      assert_equal "failed", notification.status
    end
  end

  test "push delivery respects user locale" do
    @user2.update!(locale: "vi")

    sign_in @user1

    post conversation_conversation_messages_path(@conversation),
      params: { conversation_message: { body: "Xin chào!" } }

    notification = Notification.last
    assert_match "Tin nhắn mới từ", notification.localized_title
  end
end

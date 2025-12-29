require "test_helper"

class PushFcmNotificationsTest < ActionDispatch::IntegrationTest
  setup do
    # Clear cache to ensure clean state for each test
    Rails.cache.clear

    @user1 = users(:basic_user)
    @user2 = users(:vietnamese_user)
    @conversation = conversations(:user_conversation)

    # Create mobile push endpoint for user2
    @android_endpoint = @user2.push_endpoints.create!(
      platform: "android",
      token: "fcm-token-android-123",
      device_id: "device-android-001",
      active: true,
      last_seen_at: Time.current
    )

    @ios_endpoint = @user2.push_endpoints.create!(
      platform: "ios",
      token: "fcm-token-ios-456",
      device_id: "device-ios-001",
      active: true,
      last_seen_at: Time.current
    )
  end

  test "dm message creates notification and enqueues push job for mobile" do
    sign_in @user1

    assert_difference [ "Notification.count", "enqueued_jobs.size" ] do
      post conversation_conversation_messages_path(@conversation),
        params: { conversation_message: { body: "Hello from mobile test!" } }
    end

    notification = Notification.last
    assert_equal @user2, notification.recipient
    assert_equal @user1, notification.actor
    assert_equal "dm_message", notification.kind

    # Check job was enqueued
    assert_enqueued_with(job: PushDeliveryJob, args: [ notification.id ])
  end

  test "push delivery sends to all active mobile endpoints" do
    sign_in @user1

    # Track deliveries
    deliveries = []

    # Create a stub that tracks all deliveries
    stub_client = Object.new
    stub_client.define_singleton_method(:deliver!) do |args|
      deliveries << args
      true
    end

    Push.stub :client, stub_client do
      perform_enqueued_jobs do
        post conversation_conversation_messages_path(@conversation),
          params: { conversation_message: { body: "Test to both devices" } }
      end
    end

    # Verify deliveries to both endpoints
    assert_equal 2, deliveries.count, "Should deliver to both Android and iOS endpoints"

    delivered_endpoints = deliveries.map { |d| d[:endpoint] }
    assert_includes delivered_endpoints, @android_endpoint
    assert_includes delivered_endpoints, @ios_endpoint

    # Check notification status
    notification = Notification.last
    assert_equal "delivered", notification.status
  end

  test "spam prevention limits push notifications to 1 per 10 seconds" do
    sign_in @user1

    # First message creates notification
    assert_difference "Notification.count", 1 do
      post conversation_conversation_messages_path(@conversation),
        params: { conversation_message: { body: "First message" } }
    end

    # Second message within 10 seconds does not create notification
    assert_no_difference "Notification.count" do
      post conversation_conversation_messages_path(@conversation),
        params: { conversation_message: { body: "Second message (spam)" } }
    end

    # Clear cache to simulate time passing
    Rails.cache.clear

    # Third message creates notification again
    assert_difference "Notification.count", 1 do
      post conversation_conversation_messages_path(@conversation),
        params: { conversation_message: { body: "Third message after cache clear" } }
    end
  end

  test "api endpoint registers FCM token for mobile app" do
    sign_in @user1

    assert_difference "PushEndpoint.count", 1 do
      post api_v1_push_endpoints_path, params: {
        platform: "android",
        token: "new-fcm-token-789",
        device_id: "new-device-002"
      }, as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json["success"]

    endpoint = PushEndpoint.last
    assert_equal @user1, endpoint.user
    assert_equal "android", endpoint.platform
    assert_equal "new-fcm-token-789", endpoint.token
    assert_equal "new-device-002", endpoint.device_id
    assert endpoint.active?
  end

  test "api endpoint updates existing token for same device" do
    sign_in @user2

    # Should update existing endpoint, not create new one
    assert_no_difference "PushEndpoint.count" do
      post api_v1_push_endpoints_path, params: {
        platform: "android",
        token: "updated-fcm-token",
        device_id: @android_endpoint.device_id
      }, as: :json
    end

    assert_response :success

    @android_endpoint.reload
    assert_equal "updated-fcm-token", @android_endpoint.token
    assert @android_endpoint.active?
  end

  test "api endpoint deactivates token on unregister" do
    sign_in @user2

    delete api_v1_push_endpoints_path, params: {
      platform: "android",
      token: @android_endpoint.token
    }, as: :json

    assert_response :success

    @android_endpoint.reload
    assert_not @android_endpoint.active?
  end

  test "invalid FCM tokens get deactivated after delivery failure" do
    sign_in @user1

    # Create notification first
    post conversation_conversation_messages_path(@conversation),
      params: { conversation_message: { body: "Will fail" } }

    notification = Notification.last
    assert_not_nil notification

    # Mock FCM client to simulate invalid token error
    Push.client.stub :deliver!, ->(_) { raise StandardError.new("INVALID_ARGUMENT") } do
      # Run the job directly without retries
      assert_nothing_raised do
        PushDeliveryJob.new.perform(notification.id)
      end
    end

    # Check endpoints were deactivated
    @android_endpoint.reload
    @ios_endpoint.reload
    assert_equal false, @android_endpoint.active?
    assert_equal false, @ios_endpoint.active?

    # Notification should be marked as failed
    notification.reload
    assert_equal "failed", notification.status
  end

  test "push data includes deep link for conversation" do
    sign_in @user1

    # Capture the data passed to FCM
    delivered_data = nil

    # Create a stub that captures the data
    stub_client = Object.new
    def stub_client.deliver!(args)
      @last_args = args
      true
    end

    Push.stub :client, stub_client do
      perform_enqueued_jobs do
        post conversation_conversation_messages_path(@conversation),
          params: { conversation_message: { body: "Check deep link" } }
      end

      # Get the captured args
      delivered_data = stub_client.instance_variable_get(:@last_args)[:data]
    end

    # Verify deep link data
    assert_not_nil delivered_data, "Push data should not be nil"
    assert_equal "dm_message", delivered_data[:type]
    assert_equal @conversation.id, delivered_data[:conversation_id]
    assert_match /conversations\/#{@conversation.id}/, delivered_data[:url]
  end

  test "push respects user notification settings for mobile" do
    # Disable push for user2
    @user2.update!(notification_push_enabled: false)

    sign_in @user1

    perform_enqueued_jobs do
      post conversation_conversation_messages_path(@conversation),
        params: { conversation_message: { body: "No push" } }
    end

    notification = Notification.last
    assert_equal "skipped", notification.status
    assert_equal "push_disabled", notification.failure_reason
  end
end

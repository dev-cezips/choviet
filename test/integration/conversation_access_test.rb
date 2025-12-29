require "test_helper"

class ConversationAccessTest < ActionDispatch::IntegrationTest
  setup do
    @user1 = User.create!(
      email: "user1@example.com",
      password: "password123",
      name: "User One"
    )

    @user2 = User.create!(
      email: "user2@example.com",
      password: "password123",
      name: "User Two"
    )

    @user3 = User.create!(
      email: "user3@example.com",
      password: "password123",
      name: "User Three"
    )

    @conversation = Conversation.find_or_create_direct(@user1, @user2)
  end

  test "participants can access conversation" do
    sign_in @user1, scope: :user

    get conversation_path(@conversation)
    assert_response :success
    assert_select "h3", text: @user2.display_name
  end

  test "non-participants cannot access conversation" do
    sign_in @user3, scope: :user

    get conversation_path(@conversation)
    assert_redirected_to root_path
    assert_equal "Bạn không có quyền truy cập cuộc trò chuyện này", flash[:alert]
  end

  test "updates last_read_at when viewing conversation" do
    sign_in @user1, scope: :user
    participant = @conversation.conversation_participants.find_by(user: @user1)

    # Initially nil
    assert_nil participant.last_read_at

    # Visit conversation
    get conversation_path(@conversation)

    # Should be updated
    participant.reload
    assert_not_nil participant.last_read_at
    assert participant.last_read_at > 1.minute.ago
  end

  test "can send message to conversation" do
    sign_in @user1, scope: :user

    assert_difference "ConversationMessage.count", 1 do
      post conversation_conversation_messages_path(@conversation), params: {
        conversation_message: { body: "Hello there!" }
      }
    end

    message = ConversationMessage.last
    assert_equal "Hello there!", message.body
    assert_equal @user1, message.user
    assert_equal @conversation, message.conversation
  end

  test "cannot send message to conversation you're not part of" do
    sign_in @user3, scope: :user

    assert_no_difference "ConversationMessage.count" do
      post conversation_conversation_messages_path(@conversation), params: {
        conversation_message: { body: "Trying to intrude" }
      }
    end

    assert_redirected_to root_path
  end

  test "unread count updates correctly" do
    # User1 sends a message
    @conversation.conversation_messages.create!(
      user: @user1,
      body: "First message"
    )

    # User2 has 1 unread
    assert_equal 1, @conversation.unread_count_for(@user2)
    assert_equal 0, @conversation.unread_count_for(@user1)

    # User2 reads the conversation
    sign_in @user2, scope: :user
    get conversation_path(@conversation)

    # Now no unread
    assert_equal 0, @conversation.unread_count_for(@user2)

    # User1 sends another message
    @conversation.conversation_messages.create!(
      user: @user1,
      body: "Second message"
    )

    # User2 has 1 unread again
    assert_equal 1, @conversation.unread_count_for(@user2)
  end

  test "conversation list shows unread counts" do
    # Create messages
    @conversation.conversation_messages.create!(user: @user1, body: "Hello")
    @conversation.conversation_messages.create!(user: @user2, body: "Hi there")
    @conversation.conversation_messages.create!(user: @user1, body: "How are you?")

    # User2 views list
    sign_in @user2, scope: :user
    get conversations_path

    assert_response :success
    # Should show unread badge
    assert_select ".bg-blue-500", text: "2"
  end
end

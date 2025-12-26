require "test_helper"

class ChatDmFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user1 = User.create!(
      email: "buyer@example.com",
      password: "password123",
      name: "Buyer User"
    )
    
    @user2 = User.create!(
      email: "seller@example.com", 
      password: "password123",
      name: "Seller User"
    )
    
    @post = Post.create!(
      user: @user2,
      title: "iPhone for sale",
      content: "Selling my iPhone in good condition",
      post_type: "marketplace",
      product_attributes: {
        name: "iPhone",
        price: 500000,
        condition: "good"
      }
    )
  end
  
  test "can create DM from post when logged in" do
    sign_in @user1, scope: :user
    
    get post_path(@post)
    assert_response :success
    assert_select "button", text: /Nhắn tin riêng/
    
    # Click DM button
    assert_difference "Conversation.count", 1 do
      post dm_post_path(@post)
    end
    
    conversation = Conversation.last
    assert_equal "direct", conversation.kind
    assert conversation.includes_user?(@user1)
    assert conversation.includes_user?(@user2)
    assert_redirected_to conversation_path(conversation)
  end
  
  test "cannot DM yourself" do
    sign_in @user2, scope: :user
    
    get post_path(@post)
    assert_response :success
    # Should not see DM button on own posts
    assert_select "button", text: /Nhắn tin riêng/, count: 0
    
    # Try to force DM via direct POST
    assert_no_difference "Conversation.count" do
      post dm_post_path(@post)
    end
    
    assert_redirected_to @post
    assert_equal "Bạn không thể nhắn tin cho chính mình", flash[:alert]
  end
  
  test "reuses existing conversation between same users" do
    sign_in @user1, scope: :user
    
    # First DM
    post dm_post_path(@post)
    conversation1 = Conversation.last
    
    # Create another post by same seller
    another_post = Post.create!(
      user: @user2,
      title: "Another item",
      content: "Another item for sale",
      post_type: "marketplace",
      product_attributes: {
        name: "Item",
        price: 100000,
        condition: "new_item"
      }
    )
    
    # DM from another post
    post dm_post_path(another_post)
    conversation2 = Conversation.last
    
    # Should be the same conversation
    assert_equal conversation1.id, conversation2.id
    assert_equal 1, Conversation.count
  end
  
  test "creates separate conversations for different user pairs" do
    @user3 = User.create!(
      email: "another@example.com",
      password: "password123",
      name: "Another User"
    )
    
    sign_in @user1, scope: :user
    post dm_post_path(@post)
    
    sign_in @user3, scope: :user
    post dm_post_path(@post)
    
    # Should have 2 different conversations
    assert_equal 2, Conversation.count
  end
  
  test "must be logged in to DM" do
    get post_path(@post)
    assert_response :success
    
    # No DM button when not logged in
    assert_select "button", text: /Nhắn tin riêng/, count: 0
    
    # Try direct POST without login
    post dm_post_path(@post)
    assert_redirected_to new_user_session_path
  end
end
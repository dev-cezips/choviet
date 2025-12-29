require "test_helper"

class MarketplacePostsTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "seller@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
  end

  test "creating marketplace post with price" do
    # Login
    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }
    follow_redirect!
    
    # Create marketplace post
    assert_difference("Post.count", 1) do
      assert_difference("Product.count", 1) do
        post posts_path, params: {
          post: {
            title: "iPhone 12 Pro Max",
            content: "Điện thoại iPhone 12 Pro Max còn mới, sử dụng cẩn thận",
            post_type: "marketplace",
            product_attributes: {
              price: 15000000,
              condition: "like_new",
              currency: "KRW"
            }
          }
        }
      end
    end
    
    assert_redirected_to post_path(Post.last)
    follow_redirect!
    
    # Verify post content
    assert_response :success
    assert_select "h1", "iPhone 12 Pro Max"
    assert_match "15.000.000₩", response.body
    assert_match "Như mới", response.body
  end

  test "marketplace post requires product attributes" do
    # Login
    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }
    follow_redirect!
    
    # Try to create marketplace post without price
    assert_no_difference("Post.count") do
      post posts_path, params: {
        post: {
          title: "iPhone without price",
          content: "This should fail",
          post_type: "marketplace",
          product_attributes: {
            condition: "like_new"
            # Missing price
          }
        }
      }
    end
    
    assert_response :unprocessable_entity
    assert_match "Price", response.body
  end

  test "non-marketplace posts don't save product attributes" do
    # Login
    post user_session_path, params: {
      user: { email: @user.email, password: "password123" }
    }
    follow_redirect!
    
    # Create question post with product attributes (should be ignored)
    assert_difference("Post.count", 1) do
      assert_no_difference("Product.count") do
        post posts_path, params: {
          post: {
            title: "Question about something",
            content: "This is a question, not a marketplace post",
            post_type: "question",
            product_attributes: {
              price: 999999,
              condition: "new_item"
            }
          }
        }
      end
    end
    
    post = Post.last
    assert_equal "question", post.post_type
    assert_nil post.product
  end
end
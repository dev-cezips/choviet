require "test_helper"

class FavoriteTest < ActiveSupport::TestCase
  test "user can favorite a post" do
    user = User.create!(
      email: "test@example.com",
      password: "password123"
    )

    post = Post.create!(
      user: user,
      title: "Test Post",
      content: "This is a test post content",
      post_type: "question"
    )

    favorite = Favorite.create!(user: user, post: post)

    assert favorite.valid?
    assert_equal 1, post.reload.favorites_count
  end

  test "user cannot favorite the same post twice" do
    user = User.create!(
      email: "test@example.com",
      password: "password123"
    )

    post = Post.create!(
      user: user,
      title: "Test Post",
      content: "This is a test post content",
      post_type: "question"
    )

    Favorite.create!(user: user, post: post)
    duplicate = Favorite.new(user: user, post: post)

    refute duplicate.valid?
    assert duplicate.errors[:user_id].any?
  end

  test "favorites count is updated correctly" do
    user1 = User.create!(email: "test1@example.com", password: "password123")
    user2 = User.create!(email: "test2@example.com", password: "password123")

    post = Post.create!(
      user: user1,
      title: "Popular Post",
      content: "This is a popular post content",
      post_type: "question"
    )

    assert_equal 0, post.favorites_count

    Favorite.create!(user: user1, post: post)
    assert_equal 1, post.reload.favorites_count

    Favorite.create!(user: user2, post: post)
    assert_equal 2, post.reload.favorites_count

    post.favorites.first.destroy
    assert_equal 1, post.reload.favorites_count
  end
end

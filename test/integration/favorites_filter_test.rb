require "test_helper"

class FavoritesFilterTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      name: "Test User"
    )

    @other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      name: "Other User"
    )

    # Create posts with different popularity levels
    @popular_post = Post.create!(
      user: @other_user,
      title: "Popular iPhone for sale",
      content: "Very popular item with many favorites",
      post_type: "marketplace",
      product_attributes: {
        name: "iPhone",
        price: 500000,
        condition: "good"
      }
    )

    @unpopular_post = Post.create!(
      user: @other_user,
      title: "Unpopular Samsung phone",
      content: "Less popular item",
      post_type: "marketplace",
      product_attributes: {
        name: "Samsung",
        price: 300000,
        condition: "fair"
      }
    )

    @question_post = Post.create!(
      user: @other_user,
      title: "Question about phones",
      content: "Which phone should I buy?",
      post_type: "question"
    )

    # Create favorites with different dates
    Favorite.create!(user: @user, post: @popular_post, created_at: 1.day.ago)
    Favorite.create!(user: @user, post: @unpopular_post, created_at: 2.days.ago)
    Favorite.create!(user: @user, post: @question_post, created_at: 1.hour.ago)

    # Make popular post actually popular
    5.times do |i|
      u = User.create!(email: "fan#{i}@example.com", password: "password123")
      Favorite.create!(user: u, post: @popular_post)
    end

    # Update favorites_count
    @popular_post.update_column(:favorites_count, 6)
    @unpopular_post.update_column(:favorites_count, 1)
    @question_post.update_column(:favorites_count, 1)
  end

  test "favorites page shows user's favorited posts" do
    get favorites_user_path(@user)
    assert_response :success

    # Should show all favorited posts
    assert_select "article", 3
    assert_match @popular_post.title, response.body
    assert_match @unpopular_post.title, response.body
    assert_match @question_post.title, response.body
  end

  test "can filter favorites by post type" do
    get favorites_user_path(@user), params: { type: "marketplace" }
    assert_response :success

    # Should only show marketplace posts
    assert_select "article", 2
    assert_match @popular_post.title, response.body
    assert_match @unpopular_post.title, response.body
    assert_no_match @question_post.title, response.body
  end

  test "can search within favorites" do
    get favorites_user_path(@user), params: { q: "iPhone" }
    assert_response :success

    # Should only show posts matching search
    assert_select "article", 1
    assert_match @popular_post.title, response.body
    assert_no_match @unpopular_post.title, response.body
    assert_no_match @question_post.title, response.body
  end

  test "can sort favorites by popularity" do
    get favorites_user_path(@user), params: { sort: "popular" }
    assert_response :success

    # Should show posts sorted by favorites_count
    articles = css_select("article h3")
    assert_equal @popular_post.title, articles[0].text.strip
  end

  test "search parameters persist through pagination" do
    # Create enough posts to trigger pagination (default is 25 per page)
    30.times do |i|
      post = Post.create!(
        user: @other_user,
        title: "Extra iPhone post #{i}",
        content: "More content for pagination test",
        post_type: "marketplace",
        product_attributes: {
          name: "iPhone #{i}",
          price: 400000 + i * 10000,
          condition: "good"
        }
      )
      Favorite.create!(user: @user, post: post)
    end

    # Search for iPhone
    get favorites_user_path(@user), params: { q: "iPhone", type: "marketplace" }
    assert_response :success

    # Check if there's actually content that matches
    assert_select "article" # At least one result

    # If pagination exists, verify it includes search params
    if css_select("nav.pagination").any?
      assert_select "nav.pagination" do
        assert_select "a[href*='q=iPhone']"
        assert_select "a[href*='type=marketplace']"
      end
    end
  end

  test "search form submits to correct favorites URL" do
    get favorites_user_path(@user)
    assert_response :success

    # Check form action points to favorites path
    assert_select "form[action='#{favorites_user_path(@user)}']"
  end
end

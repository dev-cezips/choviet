require "application_system_test_case"

class MarketplacePostsTest < ApplicationSystemTestCase
  setup do
    skip "JavaScript timing issues in CI - tested via integration tests" if ENV["CI"]

    @user = User.create!(
      email: "one@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    login_as(@user, scope: :user)
  end

  test "creating a marketplace post with price" do
    visit new_post_path

    # Wait for page to fully load
    sleep 1

    # Click on marketplace label instead of using radio button directly
    find("label", text: "Mua bán").click

    # Wait for JavaScript to execute
    sleep 1

    # Fill in post details
    fill_in "Tiêu đề", with: "iPhone 12 Pro Max"
    fill_in "Nội dung", with: "Điện thoại iPhone 12 Pro Max còn mới, sử dụng cẩn thận"

    # Fill in price using the data attribute selector
    find("[data-post-form-target='priceInput']").set("15000000")

    # Select condition
    select "Như mới", from: "post[product_attributes][condition]"

    click_button "Đăng bài"

    assert_text "Đã đăng bài thành công!"
    assert_text "15.000.000₩"
    assert_text "Như mới"
  end

  test "price field is hidden for non-marketplace posts" do
    visit new_post_path

    # Wait for page to fully load
    sleep 1

    # Click on question label (should be selected by default)
    find("label", text: "Hỏi đáp").click

    # Wait for JavaScript to execute
    sleep 0.5

    # Try to find marketplace fields - should not be visible
    assert_no_selector "[data-post-form-target='priceInput']", visible: true
  end
end


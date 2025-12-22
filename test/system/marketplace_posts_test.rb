require "application_system_test_case"

class MarketplacePostsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "one@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    login_as(@user, scope: :user)
  end

  test "creating a marketplace post with price" do
    visit new_post_path

    # Use the helper method from ApplicationSystemTestCase
    set_radio_and_trigger_change("post_post_type_marketplace")
    
    # Wait for marketplace fields to appear and be enabled
    assert_selector "[data-post-form-target='marketplaceFields']:not(.hidden)", wait: 5
    
    # Fill in post details
    fill_in "Tiêu đề", with: "iPhone 12 Pro Max"
    fill_in "Nội dung", with: "Điện thoại iPhone 12 Pro Max còn mới, sử dụng cẩn thận"
    
    # Fill in price by finding the field with data attribute
    price_field = find("[data-post-form-target='priceInput']")
    price_field.fill_in with: "15000000"
    
    # Select condition
    select "Như mới", from: "Tình trạng"

    click_button "Đăng bài"

    assert_text "Đã đăng bài thành công!"
    assert_text "15.000.000₩"
    assert_text "Như mới"
  end

  test "price field is hidden for non-marketplace posts" do
    visit new_post_path

    # Use the helper method to select question type
    set_radio_and_trigger_change("post_post_type_question")

    # Marketplace fields should be hidden
    assert_selector "[data-post-form-target='marketplaceFields'].hidden", wait: 2
  end
end

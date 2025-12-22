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

    # Select marketplace type using choose
    choose("post_post_type_marketplace", allow_label_click: true)
    
    # Trigger change event to ensure JavaScript handlers fire
    page.execute_script("document.getElementById('post_post_type_marketplace').dispatchEvent(new Event('change', { bubbles: true }))")

    # Fill in post details
    fill_in "Tiêu đề", with: "iPhone 12 Pro Max"
    fill_in "Nội dung", with: "Điện thoại iPhone 12 Pro Max còn mới, sử dụng cẩn thận"

    # Wait for marketplace fields to be visible and enabled
    assert_selector "[data-post-form-target='marketplaceFields']:not(.hidden)"
    
    # Wait for price field to be enabled
    find_field("Giá", disabled: false, wait: 2)

    # Fill in price
    fill_in "Giá", with: "15000000"
    select "Như mới", from: "Tình trạng"

    click_button "Đăng bài"

    assert_text "Đã đăng bài thành công!"
    assert_text "15.000.000₩"
    assert_text "Như mới"
  end

  test "price field is hidden for non-marketplace posts" do
    visit new_post_path

    # Select question type using Capybara's choose method
    choose("post_post_type_question", allow_label_click: true)

    # Verify the radio button is actually selected
    assert_equal "question", find("input[name='post[post_type]']:checked", visible: false).value

    # Trigger change event to ensure JavaScript handlers fire
    page.execute_script("document.getElementById('post_post_type_question').dispatchEvent(new Event('change', { bubbles: true }))")

    # Marketplace fields should be hidden
    assert_no_selector "[data-post-form-target='marketplaceFields']:not(.hidden)", visible: true
  end
end

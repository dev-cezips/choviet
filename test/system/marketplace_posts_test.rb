require "application_system_test_case"

class MarketplacePostsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "creating a marketplace post with price" do
    visit new_post_path
    
    # Select marketplace type
    find('input[value="marketplace"]').click
    
    # Fill in post details
    fill_in "Tiêu đề", with: "iPhone 12 Pro Max"
    fill_in "Nội dung", with: "Điện thoại iPhone 12 Pro Max còn mới, sử dụng cẩn thận"
    
    # Marketplace fields should be visible
    assert_selector "[data-post-form-target='marketplaceFields']"
    
    # Fill in price
    fill_in "Giá", with: "15000000"
    select "Như mới", from: "Tình trạng"
    
    click_on "Đăng bài"
    
    assert_text "Đã đăng bài thành công!"
    assert_text "15,000,000원"
    assert_text "Như mới"
  end
  
  test "price field is hidden for non-marketplace posts" do
    visit new_post_path
    
    # Select question type
    find('input[value="question"]').click
    
    # Marketplace fields should be hidden
    assert_no_selector "[data-post-form-target='marketplaceFields']:not(.hidden)"
  end
end
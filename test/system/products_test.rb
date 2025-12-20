require "application_system_test_case"
require "base64"
require "fileutils"

class ProductsTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email: "test_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Test User"
    )
    
    login_as(@user, scope: :user)
    
    # Create temporary directory for test images
    @upload_dir = Rails.root.join("tmp/test_uploads")
    FileUtils.mkdir_p(@upload_dir)
    
    # Create minimal test images using MiniMagick
    # Create a simple 10x10 red square
    @img1 = @upload_dir.join("sample1.jpg")
    @img2 = @upload_dir.join("sample2.jpg")
    
    # Use ImageMagick to create test images
    system("convert -size 10x10 xc:red '#{@img1}'")
    system("convert -size 10x10 xc:blue '#{@img2}'")
  end
  
  teardown do
    # Clean up temporary files
    FileUtils.rm_rf(@upload_dir) if @upload_dir && File.exist?(@upload_dir)
  end

  test "creating a product with images" do
    visit new_product_path
    
    # Fill in product details
    fill_in "Tên sản phẩm", with: "Áo thun Việt Nam"
    fill_in "Mô tả", with: "Áo thun cotton 100%, size M, màu trắng"
    fill_in "Giá", with: "150000"
    select "KRW (₩)", from: "Tiền tệ"
    select "Như mới", from: "Tình trạng"
    
    # Attach test images
    attach_file "Hình ảnh", [@img1, @img2]
    
    click_button "Tạo sản phẩm"
    
    # Verify success
    assert_text "Đã tạo sản phẩm thành công!"
    assert_text "Áo thun Việt Nam"
    assert_text "150.000₩"
    assert_text "Như mới"
    
    # Verify images are displayed
    assert_selector "img", minimum: 2
  end

  test "viewing product list" do
    # Create a test product
    product = Product.create!(
      name: "Test Product",
      price: 50000,
      currency: "KRW",
      condition: "like_new"
    )
    
    visit products_path
    
    assert_text "Test Product"
    assert_text "50.000₩"
    
    # Click to view details
    click_link "Test Product"
    
    assert_current_path product_path(product)
    assert_text "Test Product"
    assert_text "50.000₩"
    assert_text "Như mới"
  end

  test "editing a product" do
    product = Product.create!(
      name: "Original Name",
      price: 100000,
      currency: "KRW",
      condition: "good"
    )
    
    visit product_path(product)
    click_link "Sửa"
    
    fill_in "Tên sản phẩm", with: "Updated Product Name"
    fill_in "Giá", with: "200000"
    select "Mới", from: "Tình trạng"
    
    click_button "Cập nhật"
    
    assert_text "Đã cập nhật sản phẩm!"
    assert_text "Updated Product Name"
    assert_text "200.000₩"
    assert_text "Mới"
  end

  test "deleting a product" do
    product = Product.create!(
      name: "Product to Delete",
      price: 75000,
      currency: "KRW",
      condition: "fair"
    )
    
    visit product_path(product)
    
    accept_confirm do
      click_button "Xóa"
    end
    
    assert_text "Đã xóa sản phẩm!"
    assert_current_path products_path
    assert_no_text "Product to Delete"
  end

  test "product form shows validation errors" do
    visit new_product_path
    
    # Submit empty form
    click_button "Tạo sản phẩm"
    
    # Should see validation errors
    assert_text "Có lỗi xảy ra:"
    assert_text "Name không thể để trắng"
    assert_text "Price không thể để trắng"
    assert_text "Condition không thể để trắng"
  end
end
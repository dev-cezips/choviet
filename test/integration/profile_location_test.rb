# frozen_string_literal: true

require "test_helper"

class ProfileLocationTest < ActionDispatch::IntegrationTest
  setup do
    # Create locations for testing
    @seoul = Location.create!(
      code: "seoul",
      name_vi: "Seoul",
      name_ko: "서울",
      lat: 37.5665,
      lng: 126.9780,
      level: 1
    )

    @gyeonggi = Location.create!(
      code: "gyeonggi",
      name_vi: "Gyeonggi",
      name_ko: "경기도",
      lat: 37.4138,
      lng: 127.5183,
      level: 1
    )

    @ansan = Location.create!(
      code: "ansan",
      name_vi: "Ansan",
      name_ko: "안산시",
      lat: 37.3236,
      lng: 126.8219,
      level: 2
    )

    @user = User.create!(
      email: "test_#{SecureRandom.hex(4)}@example.com",
      password: "password123",
      name: "Test User"
    )
  end

  test "user can access profile edit page" do
    sign_in @user
    get edit_profile_path
    assert_response :success
    assert_select "h1", "Chỉnh sửa hồ sơ"
  end

  test "user can update name and locale" do
    sign_in @user

    patch profile_path, params: {
      user: {
        name: "Updated Name",
        locale: "ko",
        location_code: "seoul"
      }
    }

    assert_redirected_to me_path
    follow_redirect!
    assert_response :success

    @user.reload
    assert_equal "Updated Name", @user.name
    assert_equal "ko", @user.locale
    assert_equal "seoul", @user.location_code
  end

  test "location_code is required on update" do
    sign_in @user

    patch profile_path, params: {
      user: {
        name: "Updated Name",
        location_code: ""
      }
    }

    assert_response :unprocessable_entity
    assert_select ".text-red-700", /Location code/
  end

  test "user can save GPS coordinates with location" do
    sign_in @user

    patch profile_path, params: {
      user: {
        location_code: "seoul",
        latitude: 37.5665,
        longitude: 126.9780
      }
    }

    assert_redirected_to me_path
    @user.reload
    assert_equal "seoul", @user.location_code
    assert_in_delta 37.5665, @user.latitude, 0.0001
    assert_in_delta 126.9780, @user.longitude, 0.0001
  end

  test "server auto-detects location from GPS coordinates" do
    sign_in @user

    # Send GPS coords near Seoul without location_code
    patch profile_path, params: {
      user: {
        latitude: 37.5665,
        longitude: 126.9780
      }
    }

    assert_redirected_to me_path
    @user.reload
    assert_equal "seoul", @user.location_code, "Should auto-detect Seoul from coordinates"
    assert_in_delta 37.5665, @user.latitude, 0.0001
    assert_in_delta 126.9780, @user.longitude, 0.0001
  end

  test "profile edit page shows location warning when location_code is blank" do
    sign_in @user
    get edit_profile_path
    assert_response :success
    assert_select ".text-amber-600", /Vui lòng chọn khu vực/
  end

  test "profile edit page includes GPS location button" do
    sign_in @user
    get edit_profile_path
    assert_response :success
    assert_select "#detect-location-btn", "Dùng vị trí hiện tại"
  end

  test "profile edit page includes location options from database" do
    sign_in @user
    get edit_profile_path
    assert_response :success

    assert_select "select#user_location_code option[value='seoul']", "Seoul"
    assert_select "select#user_location_code option[value='gyeonggi']", "Gyeonggi"
    assert_select "select#user_location_code option[value='ansan']", "Ansan"
  end

  test "profile edit page includes language selection" do
    sign_in @user
    get edit_profile_path
    assert_response :success

    assert_select "select#user_locale option[value='vi']", "Tiếng Việt"
    assert_select "select#user_locale option[value='ko']", "한국어"
    assert_select "select#user_locale option[value='en']", "English"
  end

  test "user without location_code can create account but must set it on update" do
    # User created without location_code
    assert_nil @user.location_code

    sign_in @user

    # Try to update without location_code
    patch profile_path, params: {
      user: {
        name: "New Name"
      }
    }

    assert_response :unprocessable_entity

    # Update with location_code succeeds
    patch profile_path, params: {
      user: {
        name: "New Name",
        location_code: "seoul"
      }
    }

    assert_redirected_to me_path
    @user.reload
    assert_equal "New Name", @user.name
    assert_equal "seoul", @user.location_code
  end

  test "profile edit page shows warning when no locations in database" do
    # Delete all locations
    Location.destroy_all

    sign_in @user
    get edit_profile_path
    assert_response :success

    assert_select ".text-red-600", /Không có khu vực nào trong hệ thống/
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end

# frozen_string_literal: true

require "test_helper"

class AuthSignupLoginTest < ActionDispatch::IntegrationTest
  test "user can sign up and then is signed in" do
    get new_user_registration_path
    assert_response :success

    post user_registration_path, params: {
      user: {
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
  end

  test "user can sign in" do
    user = User.create!(
      email: "user@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }

    assert_redirected_to root_path
  end

  test "user cannot sign in with wrong password" do
    user = User.create!(
      email: "user2@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    post user_session_path, params: {
      user: { email: user.email, password: "wrong" }
    }

    assert_response :unprocessable_entity
  end
end

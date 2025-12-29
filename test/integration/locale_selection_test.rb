require "test_helper"

class LocaleSelectionTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  setup do
    # 세션/로케일 영향 최소화
    I18n.locale = I18n.default_locale

    @owner = User.create!(
      email: "locale_owner@test.com",
      password: "password123",
      name: "Owner",
      locale: "vi"
    )

    @post = @owner.posts.create!(
      title: "Locale test post",
      content: "Hello world! This is a test post for locale selection.",
      post_type: "free_talk",
      status: "active"
    )
  end

  test "params locale temporarily overrides but does not persist" do
    # params locale은 해당 요청에만 적용됨
    get post_path(@post), params: { locale: "ko" }
    assert_equal :ko, I18n.locale

    # session에 저장되지 않았으므로 다음 요청에서는 default locale
    get post_path(@post)
    assert_equal I18n.default_locale, I18n.locale
  end

  test "invalid params locale falls back to default" do
    get post_path(@post), params: { locale: "zz" }
    assert_equal I18n.default_locale, I18n.locale
  end

  test "current_user locale is used when no params or session" do
    user = User.create!(
      email: "korean_user@test.com",
      password: "password123",
      name: "Korean",
      locale: "ko"
    )

    sign_in user

    get post_path(@post)
    assert_equal :ko, I18n.locale
  end

  test "Accept-Language is used when no params session or user" do
    get post_path(@post), headers: { "Accept-Language" => "ko-KR,ko;q=0.9,en;q=0.8" }
    assert_equal :ko, I18n.locale
  end

  test "default locale is used when nothing provided" do
    get post_path(@post)
    assert_equal I18n.default_locale, I18n.locale
  end

  test "locale normalization handles variants correctly" do
    # ko-KR should normalize to ko
    get post_path(@post), params: { locale: "ko-KR" }
    assert_equal :ko, I18n.locale

    # EN should normalize to en
    get post_path(@post), params: { locale: "EN" }
    assert_equal :en, I18n.locale
  end

  test "change_locale action updates session for valid locale" do
    get set_locale_path(locale: "ko")
    assert_response :redirect

    # Check that locale persists in session
    get post_path(@post)
    assert_equal :ko, I18n.locale
  end

  test "change_locale action ignores invalid locale" do
    get set_locale_path(locale: "invalid")
    assert_response :redirect

    # Should still use default locale
    get post_path(@post)
    assert_equal I18n.default_locale, I18n.locale
  end

  test "session persistence works only through change_locale action" do
    # Direct param does not persist to session
    get post_path(@post), params: { locale: "ko" }
    assert_equal :ko, I18n.locale

    get post_path(@post)
    assert_equal I18n.default_locale, I18n.locale

    # But change_locale action does persist
    get set_locale_path(locale: "ko")
    get post_path(@post)
    assert_equal :ko, I18n.locale
  end
end

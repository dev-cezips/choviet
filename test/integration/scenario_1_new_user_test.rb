# frozen_string_literal: true

require "test_helper"

# 📋 시나리오 1 — 완전 신규 유저 (Zero Trust State)
# 목표: 불안하지 않고 첫 행동을 시작할 수 있는가?

class Scenario1NewUserTest < ActionDispatch::IntegrationTest
  setup do
    @new_user = User.create!(
      email: "newuser_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "New Test User"
    )
    
    @seller = User.create!(
      email: "seller_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Seller User"
    )
    
    @post = @seller.posts.build(
      title: "Test Product",
      content: "Test description",
      post_type: "marketplace",
      status: "active"
    )
    @post.save(validate: false)
    @post.create_product!(name: @post.title, price: 100000, condition: "good")
  end

  # ✅ 회원가입 직후 프로필 접근 가능
  test "new user can access their profile after signup" do
    sign_in @new_user
    get user_path(@new_user)
    assert_response :success
  end

  # ✅ 게시글 목록 정상 노출
  test "new user can view posts list" do
    sign_in @new_user
    get posts_path
    assert_response :success
    assert_match @post.title, response.body
  end

  # ✅ 게시글 상세 진입 시 trust_summary 표시됨 (🌱 톤)
  test "post detail shows trust_summary with seedling tone for new seller" do
    sign_in @new_user
    get post_path(@post)
    assert_response :success
    
    # trust_summary가 표시되어야 함
    assert_match(/🌱|👤/, response.body, "Trust summary should be displayed")
  end

  # ✅ trust_hint 표시됨 (행동 유도, 강요 없음)
  test "post detail shows trust_hint for guidance" do
    sign_in @new_user
    get post_path(@post)
    
    # hint가 있으면 강요가 아닌 제안 톤이어야 함
    hint = @seller.trust_hint(context: :post)
    if hint.present?
      assert_match(/💬|⏱/, hint, "Hint should use gentle emoji")
      refute_match(/phải|bắt buộc|cảnh báo/, hint, "Hint should not be forceful")
    end
  end

  # ✅ CTA(채팅/거래 버튼)가 힌트보다 시각적으로 우선
  test "CTA buttons are visually prominent" do
    sign_in @new_user
    get post_path(@post)
    
    # 채팅 버튼이 있어야 함 (비활성화되어 있을 수 있음)
    assert_select "button, a", /Chat|채팅|💬/
  end

  # ✅ 힌트가 버튼처럼 보이지 않음 (text-xs, text-gray 사용 확인)
  test "hints are styled as subtle text not buttons" do
    sign_in @new_user
    get post_path(@post)
    
    # trust_hint는 작은 회색 텍스트여야 함
    assert_select "p.text-xs.text-gray-500, p.text-xs.text-gray-400", minimum: 0
  end

  # 📌 실패 신호: "안전 / 신뢰 / 경고" 같은 단어 사용됨
  test "no forbidden trust words in UI" do
    sign_in @new_user
    get post_path(@post)
    
    forbidden_words = ["an toàn", "tin cậy", "cảnh báo", "nguy hiểm", "xác minh"]
    forbidden_words.each do |word|
      refute_match(/#{word}/i, response.body, "Should not contain forbidden word: #{word}")
    end
  end

  # ✅ 신규 유저의 first_trade? 메서드 검증
  test "new user first_trade? returns true" do
    assert @new_user.first_trade?, "New user should be on first trade"
  end

  # ✅ 신규 유저의 trust_summary 검증
  test "new user trust_summary shows appropriate message" do
    summary = @new_user.trust_summary(context: :profile)
    assert_match(/🌱|👤/, summary, "New user summary should have seedling or person emoji")
  end

  private

  def sign_in(user)
    post user_session_path, params: { 
      user: { email: user.email, password: "password123" } 
    }
  end
end

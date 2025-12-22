# frozen_string_literal: true

require "test_helper"

# 📋 시나리오 4 — 휴면 유저 (Dormant → Return)
# 목표: 다시 돌아온 유저에게 조용히 방향을 제시하는가?

class Scenario4DormantUserTest < ActionDispatch::IntegrationTest
  setup do
    @dormant_user = User.create!(
      email: "dormant_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Dormant User",
      created_at: 90.days.ago
    )

    @seller = User.create!(
      email: "seller_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Seller User"
    )

    @post = @seller.posts.build(
      title: "Product for Dormant User",
      content: "Description",
      post_type: "marketplace"
    )
    @post.save(validate: false)
    @post.create_product!(name: @post.title, price: 100000, condition: "good")

    # 과거 거래 생성 (40일 전)
    old_seller = User.create!(
      email: "oldseller_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Old Seller"
    )

    old_post = old_seller.posts.build(
      title: "Old Product",
      content: "Description",
      post_type: "marketplace",
      created_at: 60.days.ago
    )
    old_post.save(validate: false)
    old_post.create_product!(name: old_post.title, price: 50000, condition: "good")

    @old_chat_room = ChatRoom.create!(
      post: old_post,
      buyer: @dormant_user,
      seller: old_seller,
      trade_status: "completed",
      created_at: 45.days.ago,
      updated_at: 45.days.ago
    )

    # 과거 리뷰 (40일 전)
    Review.create!(
      chat_room: @old_chat_room,
      reviewer: old_seller,
      reviewee: @dormant_user,
      rating: 4,
      comment: "Good buyer",
      created_at: 45.days.ago
    )

    # 과거 메시지 (마지막 활동 40일 전)
    Message.create!(
      chat_room: @old_chat_room,
      sender: @dormant_user,
      content_raw: "Old message",
      created_at: 40.days.ago
    )
  end

  # ✅ 30일 이상 비활동 유저로 설정 확인
  test "dormant user has no recent activity" do
    assert_not @dormant_user.recently_active?(within: 30.days),
      "Dormant user should not be recently active"
  end

  # ✅ 🌙 trust_summary 표시
  test "dormant user sees moon emoji summary" do
    summary = @dormant_user.trust_summary(context: :post)
    assert_match(/🌙/, summary, "Dormant user should see moon emoji for inactive status")
  end

  # ✅ trust_hint 재등장
  test "trust_hint reappears for dormant user" do
    hint = @dormant_user.trust_hint(context: :post)
    assert hint.present?, "Hint should reappear for dormant user"
  end

  # ✅ 힌트 문구가 경고 아님
  test "hint is not a warning" do
    hint = @dormant_user.trust_hint(context: :post)

    # 경고성 단어가 없어야 함
    forbidden_words = [ "cảnh báo", "nguy hiểm", "chú ý", "warning", "danger" ]
    forbidden_words.each do |word|
      refute_match(/#{word}/i, hint, "Hint should not contain warning word: #{word}")
    end
  end

  # ✅ 힌트 문구가 행동 제안 수준
  test "hint is a gentle suggestion" do
    hint = @dormant_user.trust_hint(context: :post)

    # 제안/권유 단어 사용
    suggestion_patterns = [ "nên", "hãy", "có thể", "💬" ]
    has_suggestion = suggestion_patterns.any? { |p| hint.include?(p) }

    assert has_suggestion, "Hint should be a gentle suggestion"
  end

  # ✅ UX가 부담스럽지 않음
  test "UX is not overwhelming" do
    sign_in @dormant_user
    get post_path(@post)

    # 여러 개의 경고/배너가 쌓이지 않아야 함
    warning_count = response.body.scan(/bg-red|bg-yellow|⚠️|🚨/).count
    assert warning_count <= 1, "Should not have multiple warnings"
  end

  # 📌 실패 신호: "주의 / 위험" 같은 문구 없음
  test "no danger words in dormant user UI" do
    sign_in @dormant_user
    get post_path(@post)

    danger_words = [ "주의", "위험", "nguy hiểm", "cảnh báo nghiêm trọng" ]
    danger_words.each do |word|
      refute_match(/#{word}/i, response.body, "Should not contain danger word: #{word}")
    end
  end

  # 📌 실패 신호: 복귀 유저에게 죄책감 유발 안함
  test "no guilt-inducing language for returning user" do
    hint = @dormant_user.trust_hint(context: :post)
    summary = @dormant_user.trust_summary(context: :post)

    guilt_words = [ "bỏ rơi", "vắng mặt quá lâu", "đã quên", "không còn" ]
    combined_text = "#{hint} #{summary}"

    guilt_words.each do |word|
      refute_match(/#{word}/i, combined_text, "Should not guilt-trip returning user")
    end
  end

  # ✅ 휴면 유저가 다시 활동하면 힌트 사라짐
  test "hint disappears when dormant user becomes active again" do
    # 새 메시지 생성 (활동 재개)
    new_chat = ChatRoom.create!(
      post: @post,
      buyer: @dormant_user,
      seller: @seller,
      trade_status: "negotiating"
    )

    Message.create!(
      chat_room: new_chat,
      sender: @dormant_user,
      content_raw: "I'm back!",
      created_at: Time.current
    )

    @dormant_user.reload

    # 이제 recently_active가 true가 되어야 함
    assert @dormant_user.recently_active?(within: 7.days),
      "User should now be recently active"

    # 첫 거래가 아니고 활동적이면 힌트 없음
    if !@dormant_user.first_trade? && @dormant_user.recently_active?(within: 30.days)
      hint = @dormant_user.trust_hint(context: :post)
      assert_nil hint, "Hint should disappear after user becomes active"
    end
  end

  # ✅ trust_summary는 과거 평판 반영
  test "trust_summary reflects past reputation" do
    summary = @dormant_user.trust_summary(context: :profile)

    # 과거 리뷰가 있으므로 관련 정보 표시
    assert summary.present?, "Summary should exist"
    assert_match(/🌙|đánh giá|hoạt động/, summary,
      "Summary should mention past activity or reviews")
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end

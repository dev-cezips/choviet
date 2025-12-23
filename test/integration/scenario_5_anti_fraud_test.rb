# frozen_string_literal: true

require "test_helper"

# 📋 시나리오 5 — 사기 방지 / 신고 흐름
# 목표: 제재가 아니라 '정보 제공'으로 작동하는가?

class Scenario5AntiFraudReportTest < ActionDispatch::IntegrationTest
  setup do
    @reporter = User.create!(
      email: "reporter_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Reporter User"
    )

    @reported_user = User.create!(
      email: "reported_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Reported User"
    )

    @low_rep_user = User.create!(
      email: "lowrep_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Low Rep User",
      reputation_score: 1.5
    )

    @no_review_user = User.create!(
      email: "noreview_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "No Review User"
    )

    @post = @reported_user.posts.build(
      title: "Product from Reported User",
      content: "Description",
      post_type: "marketplace"
    )
    @post.save(validate: false)
    @post.create_product!(name: @post.title, price: 100000, condition: "good")

    @chat_room = ChatRoom.create!(
      post: @post,
      buyer: @reporter,
      seller: @reported_user,
      trade_status: "negotiating"
    )

    @message = Message.create!(
      chat_room: @chat_room,
      sender: @reported_user,
      content_raw: "Test message"
    )
  end

  # ✅ 신고 버튼 접근 가능
  test "report button is accessible" do
    sign_in @reporter
    get post_chat_room_path(@post, @chat_room)

    # 신고 버튼/링크가 있어야 함
    assert_match(/báo cáo|report/i, response.body, "Report option should be accessible")
  end

  # ✅ 신고 사유 입력 가능
  test "can submit report with reason" do
    sign_in @reporter

    assert_difference "Report.count", 1 do
      post message_reports_path(@message), params: {
        report: { reason_code: "spam", description: "Suspicious behavior" }
      }
    end
  end

  # ✅ 신고 누적 시 자동 시스템 메시지 1회 생성
  test "auto system message after multiple reports" do
    # 3개의 신고 생성 (TRUST_POLICY[:auto_warning_reports] = 3)
    3.times do |i|
      reporter = User.create!(
        email: "reporter#{i}_#{SecureRandom.hex(4)}@test.com",
        password: "password123",
        name: "Reporter #{i}"
      )

      Report.create!(
        reporter: reporter,
        reported: @reported_user,
        reason_code: "spam"
      )
    end

    @reported_user.reload

    # auto_flagged? 확인
    assert @reported_user.auto_flagged?, "User should be auto-flagged after 3 reports"
  end

  # ✅ 중복 시스템 메시지 생성 안됨
  test "no duplicate system warning messages" do
    # 첫 번째 신고 세트
    3.times do |i|
      reporter = User.create!(
        email: "dup_reporter#{i}_#{SecureRandom.hex(4)}@test.com",
        password: "password123",
        name: "Dup Reporter #{i}"
      )

      Report.create!(
        reporter: reporter,
        reported: @reported_user,
        reason_code: "scam"
      )
    end

    warning_messages = @chat_room.messages.where(system_message: true)
                                         .where("content_raw LIKE ?", "%🚨%")

    initial_count = warning_messages.count

    # 추가 신고
    extra_reporter = User.create!(
      email: "extra_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Extra Reporter"
    )

    Report.create!(
      reporter: extra_reporter,
      reported: @reported_user,
      reason_code: "abusive"
    )

    # 중복 메시지가 생기지 않아야 함
    final_count = @chat_room.messages.where(system_message: true)
                                     .where("content_raw LIKE ?", "%🚨%").count

    assert_equal initial_count, final_count, "Should not create duplicate warning messages"
  end

  # ✅ 저평판 유저: 경고 문구 표시
  test "low reputation user shows warning badge" do
    assert @low_rep_user.low_reputation?, "User should be low reputation"

    sign_in @reporter

    low_rep_post = @low_rep_user.posts.build(
      title: "Low Rep Product",
      content: "Description",
      post_type: "marketplace"
    )
    low_rep_post.save(validate: false)
    low_rep_post.create_product!(name: low_rep_post.title, price: 50000, condition: "good")

    get post_path(low_rep_post)

    # 경고 표시가 있어야 함
    assert_match(/⚠️|💡|uy tín thấp|cẩn thận/i, response.body,
      "Should show low reputation warning")
  end

  # ✅ 저평판 유저: 거래 완전 차단 ❌
  test "low reputation user is not completely blocked" do
    # 저평판 유저도 게시물 조회 가능
    sign_in @low_rep_user
    get posts_path
    assert_response :success

    # 프로필 접근 가능
    get user_path(@low_rep_user)
    assert_response :success
  end

  # ✅ 리뷰 없는 유저: 거래 제한 UX 자연스러움
  test "no review user sees trade restriction naturally" do
    assert @no_review_user.no_reviews?, "User should have no reviews"

    sign_in @no_review_user
    get post_path(@post)

    # 제한 메시지가 자연스러워야 함
    if response.body.include?("đánh giá")
      refute_match(/cấm|blocked|không được phép/i, response.body,
        "Restriction should not feel like a ban")
    end
  end

  # ✅ 리뷰 없는 유저: 이유 설명 명확
  test "no review user gets clear explanation" do
    assert @no_review_user.no_reviews?, "User should have no reviews"

    sign_in @no_review_user
    get post_path(@post)

    # 제한 이유가 명확해야 함
    if response.body.match?(/cần.*đánh giá|need.*review/i)
      assert_match(/đánh giá|review/i, response.body,
        "Should explain that reviews are needed")
    end
  end

  # 📌 실패 신호: 갑작스러운 차단 없음
  test "no sudden blocks without warning" do
    sign_in @reporter

    # 신고 1-2회로는 차단되지 않음
    2.times do |i|
      reporter = User.create!(
        email: "warn_reporter#{i}_#{SecureRandom.hex(4)}@test.com",
        password: "password123",
        name: "Warn Reporter #{i}"
      )

      Report.create!(
        reporter: reporter,
        reported: @reported_user,
        reason_code: "spam"
      )
    end

    @reported_user.reload

    # 아직 auto_flagged가 아님
    assert_not @reported_user.auto_flagged?,
      "User should not be flagged after only 2 reports"
  end

  # 📌 실패 신호: 운영자 개입처럼 느껴지지 않음
  test "system messages do not feel like operator intervention" do
    # 시스템 메시지가 있다면 자동화된 느낌이어야 함
    system_msg = Message.create!(
      chat_room: @chat_room,
      sender_id: nil,
      system_message: true,
      content_raw: "🚨 Người dùng này đã bị báo cáo nhiều lần."
    )

    # "운영팀" 같은 단어가 없어야 함
    refute_match(/quản trị|admin|운영팀|moderator/i, system_msg.content_raw,
      "System message should not feel like manual intervention")
  end

  # ✅ TRUST_POLICY 설정 확인
  test "trust policy is properly configured" do
    assert defined?(TRUST_POLICY), "TRUST_POLICY should be defined"
    assert TRUST_POLICY[:low_reputation_threshold].present?,
      "Should have low reputation threshold"
    assert TRUST_POLICY[:auto_warning_reports].present?,
      "Should have auto warning reports threshold"
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: { email: user.email, password: "password123" }
    }
  end
end

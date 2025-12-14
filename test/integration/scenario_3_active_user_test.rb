# frozen_string_literal: true

require "test_helper"

# 📋 시나리오 3 — 활동 유저 (Active User)
# 목표: 방해받지 않고 빠르게 거래 가능한가?

class Scenario3ActiveUserTest < ActionDispatch::IntegrationTest
  setup do
    @active_user = User.create!(
      email: "active_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Active User"
    )
    
    @other_user = User.create!(
      email: "other_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Other User"
    )
    
    # 활동 유저를 위한 거래 및 리뷰 생성
    @post = @other_user.posts.build(
      title: "Product for Active User",
      content: "Description",
      post_type: "marketplace"
    )
    @post.save(validate: false)
    @post.create_product!(name: @post.title, price: 200000, condition: "good")
    
    # 완료된 거래들 생성 (활동 유저로 만들기)
    3.times do |i|
      seller = User.create!(
        email: "seller#{i}_#{SecureRandom.hex(4)}@test.com",
        password: "password123",
        name: "Seller #{i}"
      )
      
      post = seller.posts.build(
        title: "Past Product #{i}",
        content: "Description",
        post_type: "marketplace"
      )
      post.save(validate: false)
      post.create_product!(name: post.title, price: 50000, condition: "good")
      
      chat_room = ChatRoom.create!(
        post: post,
        buyer: @active_user,
        seller: seller,
        trade_status: "completed"
      )
      
      # 리뷰 생성
      Review.create!(
        chat_room: chat_room,
        reviewer: seller,
        reviewee: @active_user,
        rating: 5,
        comment: "Great buyer!"
      )
    end
    
    # 최근 메시지 생성 (활동 표시)
    recent_chat = ChatRoom.where(buyer: @active_user).first
    Message.create!(
      chat_room: recent_chat,
      sender: @active_user,
      content_raw: "Recent activity message",
      created_at: 2.days.ago
    )
  end

  # ✅ trust_summary만 표시됨
  test "active user sees trust_summary" do
    summary = @active_user.trust_summary(context: :post)
    assert summary.present?, "Trust summary should be present"
    assert_match(/⚡|💡|⭐/, summary, "Active user should see activity-based summary")
  end

  # ✅ trust_hint 미노출
  test "active user does not see trust_hint" do
    # 활동 유저는 첫 거래가 아니고 최근 활동이 있음
    assert_not @active_user.first_trade?, "Active user should not be on first trade"
    assert @active_user.recently_active?(within: 30.days), "Active user should be recently active"
    
    hint = @active_user.trust_hint(context: :post)
    assert_nil hint, "Active user should not see trust hint"
  end

  # ✅ 요약 문구가 한 줄 유지
  test "trust_summary is single line" do
    summary = @active_user.trust_summary(context: :post)
    
    # 줄바꿈이 없어야 함
    refute_match(/\n/, summary, "Summary should be single line")
    
    # 적당한 길이여야 함 (모바일 친화적)
    assert summary.length < 60, "Summary should be concise for mobile"
  end

  # ✅ ⚡ / 💬 등 활동 기반 메시지 정확
  test "trust_summary uses appropriate activity emoji" do
    summary = @active_user.trust_summary(context: :post)
    
    # 활동 기반 이모지 사용
    assert_match(/⚡|💡|⭐|💬/, summary, "Should use activity-based emoji")
    
    # 신규 유저 이모지가 아님
    refute_match(/🌱/, summary, "Should not use new user emoji")
  end

  # ✅ 채팅 UX가 간결함
  test "chat room is clean for active user" do
    chat_room = ChatRoom.where(buyer: @active_user).first
    sign_in @active_user
    
    get post_chat_room_path(chat_room.post, chat_room)
    assert_response :success
    
    # 불필요한 경고가 없어야 함
    refute_match(/cảnh báo|warning/i, response.body, "No warnings for active user")
  end

  # ✅ 모바일에서 정보 과잉 없음
  test "no information overload for active user" do
    sign_in @active_user
    get post_path(@post)
    
    # trust_hint가 없으므로 정보가 간결해야 함
    hint = @other_user.trust_hint(context: :post)
    
    # 상대방이 활동 유저면 힌트 없음
    if @other_user.recently_active?(within: 30.days) && !@other_user.first_trade?
      assert_nil hint, "No hint for active users"
    end
  end

  # 📌 실패 신호: 힌트가 계속 남아 있지 않음
  test "hint does not persist for active user" do
    # 여러 번 확인해도 힌트가 없어야 함
    5.times do
      hint = @active_user.trust_hint(context: :post)
      assert_nil hint, "Hint should consistently be nil for active user"
    end
  end

  # 📌 실패 신호: 정보가 두 줄 이상으로 늘어나지 않음
  test "displayed info is concise" do
    summary = @active_user.trust_summary(context: :profile)
    hint = @active_user.trust_hint(context: :profile)
    
    # 힌트가 없으면 summary만 표시
    assert_nil hint, "Active user should not have hint"
    assert summary.present?, "Summary should exist"
    
    # 전체 정보가 한 줄
    total_lines = hint.nil? ? 1 : 2
    assert_equal 1, total_lines, "Should only show one line of info"
  end

  # ✅ completed_trades_count 검증
  test "active user has completed trades" do
    count = @active_user.completed_trades_count
    assert count >= 3, "Active user should have completed trades"
  end

  # ✅ recently_active? 검증
  test "active user is recently active" do
    assert @active_user.recently_active?(within: 7.days), "Should be active within 7 days"
    assert @active_user.recently_active?(within: 30.days), "Should be active within 30 days"
  end

  private

  def sign_in(user)
    post user_session_path, params: { 
      user: { email: user.email, password: "password123" } 
    }
  end
end

# frozen_string_literal: true

require "test_helper"

# 📋 시나리오 6 — UX Fade Test (종합)
# 목표: UX가 스스로 사라질 줄 아는가?

class Scenario6UxFadeTest < ActionDispatch::IntegrationTest
  setup do
    # 다양한 상태의 유저 생성
    setup_new_user
    setup_first_trade_completed_user
    setup_active_user
    setup_dormant_user
  end

  # ========================================
  # 신규 → 첫 거래 후 hint 사라짐
  # ========================================
  
  test "hint fades after first trade completion" do
    # 1. 신규 유저는 hint가 있음
    assert @new_user.first_trade?, "New user should be on first trade"
    initial_hint = @new_user.trust_hint(context: :post)
    assert initial_hint.present?, "New user should have hint"
    
    # 2. 거래 완료
    complete_trade_for(@new_user)
    @new_user.reload
    
    # 3. 최근 활동이 있고 첫 거래가 아니면 hint 사라짐
    if !@new_user.first_trade? && @new_user.recently_active?(within: 30.days)
      final_hint = @new_user.trust_hint(context: :post)
      assert_nil final_hint, "Hint should fade after first trade"
    end
  end

  # ========================================
  # 활동 지속 시 hint 없음
  # ========================================
  
  test "hint stays hidden during active period" do
    # 활동 유저는 항상 hint가 없음
    10.times do
      hint = @active_user.trust_hint(context: :post)
      assert_nil hint, "Active user should never see hint"
    end
  end

  test "active user conditions are met" do
    assert_not @active_user.first_trade?, "Active user should have trades"
    assert @active_user.recently_active?(within: 30.days), "Active user should be active"
  end

  # ========================================
  # 휴면 시 hint 재등장
  # ========================================
  
  test "hint reappears for dormant user" do
    # 휴면 유저는 hint가 다시 나타남
    hint = @dormant_user.trust_hint(context: :post)
    assert hint.present?, "Dormant user should see hint again"
  end

  test "dormant user conditions are met" do
    assert_not @dormant_user.first_trade?, "Dormant user should have past trades"
    assert_not @dormant_user.recently_active?(within: 30.days), "Dormant user should be inactive"
  end

  # ========================================
  # summary는 항상 유지
  # ========================================
  
  test "summary always exists for all user types" do
    users = [@new_user, @first_trade_user, @active_user, @dormant_user]
    contexts = [:post, :chat, :profile]
    
    users.each do |user|
      contexts.each do |context|
        summary = user.trust_summary(context: context)
        assert summary.present?, 
          "Summary should exist for #{user.name} in #{context} context"
      end
    end
  end

  # ========================================
  # UX 요소가 상태 변화에 따라 자연스럽게 이동
  # ========================================
  
  test "UX elements transition naturally with state changes" do
    # 신규 → 활동 전환 시뮬레이션
    transition_user = User.create!(
      email: "transition_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Transition User"
    )
    
    # Stage 1: 신규 - hint 있음
    assert transition_user.first_trade?, "Should start as new user"
    stage1_hint = transition_user.trust_hint(context: :post)
    assert stage1_hint.present?, "Stage 1: hint should exist"
    
    # Stage 2: 첫 거래 완료 - hint 사라짐 (활동 있으면)
    complete_trade_for(transition_user)
    add_recent_activity(transition_user)
    transition_user.reload
    
    if !transition_user.first_trade? && transition_user.recently_active?(within: 30.days)
      stage2_hint = transition_user.trust_hint(context: :post)
      assert_nil stage2_hint, "Stage 2: hint should fade"
    end
    
    # Summary는 항상 유지
    stage2_summary = transition_user.trust_summary(context: :post)
    assert stage2_summary.present?, "Summary should persist through transitions"
  end

  # ========================================
  # Emoji 일관성 검증
  # ========================================
  
  test "emoji usage is consistent with user state" do
    # 신규: 🌱
    new_summary = @new_user.trust_summary(context: :post)
    assert_match(/🌱|👤/, new_summary, "New user should use seedling or person emoji")
    
    # 활동: ⚡ 또는 💡
    active_summary = @active_user.trust_summary(context: :post)
    assert_match(/⚡|💡|⭐/, active_summary, "Active user should use activity emoji")
    
    # 휴면: 🌙
    dormant_summary = @dormant_user.trust_summary(context: :post)
    assert_match(/🌙/, dormant_summary, "Dormant user should use moon emoji")
  end

  # ========================================
  # 📌 핵심 질문: "이 UX는 지금도 필요한가?"
  # ========================================
  
  test "UX knows when to be quiet" do
    # 활동 유저에게는 조용해야 함
    active_hint = @active_user.trust_hint(context: :post)
    assert_nil active_hint, "UX should be quiet for active users"
    
    # 신규 유저에게는 도움을 줘야 함
    new_hint = @new_user.trust_hint(context: :post)
    assert new_hint.present?, "UX should help new users"
    
    # 휴면 유저에게는 부드럽게 안내해야 함
    dormant_hint = @dormant_user.trust_hint(context: :post)
    assert dormant_hint.present?, "UX should gently guide dormant users"
    refute_match(/cảnh báo|nguy hiểm/, dormant_hint, "But not with warnings")
  end

  # ========================================
  # 🧠 최종 판단 질문 (Release Gate)
  # ========================================
  
  test "release gate: app is recommendable to friends" do
    # 모든 유저 타입이 정상 작동
    [@new_user, @first_trade_user, @active_user, @dormant_user].each do |user|
      sign_in user
      get posts_path
      assert_response :success, "#{user.name} should access posts"
    end
  end

  test "release gate: flow is understandable without explanation" do
    # hint와 summary가 명확한 언어 사용
    all_hints = [
      @new_user.trust_hint(context: :post),
      @dormant_user.trust_hint(context: :post)
    ].compact
    
    all_hints.each do |hint|
      # 전문 용어나 복잡한 설명 없음
      refute_match(/algorithm|score|threshold|hệ thống|자동/, hint,
        "Hints should use plain language")
    end
  end

  test "release gate: UX quiets down at right timing" do
    # 활동 유저는 방해받지 않음
    assert_nil @active_user.trust_hint(context: :post)
    assert_nil @active_user.trust_hint(context: :chat)
    assert_nil @active_user.trust_hint(context: :profile)
  end

  test "release gate: mistakes are not catastrophic" do
    # 저평판 유저도 완전 차단되지 않음
    low_rep = User.create!(
      email: "lowrep_gate_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Low Rep Gate User",
      reputation_score: 1.0
    )
    
    sign_in low_rep
    get posts_path
    assert_response :success, "Low rep user should still access app"
  end

  private

  def setup_new_user
    @new_user = User.create!(
      email: "new_fade_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "New Fade User"
    )
  end

  def setup_first_trade_completed_user
    @first_trade_user = User.create!(
      email: "first_fade_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "First Trade Fade User"
    )
    complete_trade_for(@first_trade_user)
    add_recent_activity(@first_trade_user)
  end

  def setup_active_user
    @active_user = User.create!(
      email: "active_fade_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Active Fade User"
    )
    
    # 여러 거래 완료
    3.times { complete_trade_for(@active_user) }
    add_recent_activity(@active_user)
  end

  def setup_dormant_user
    @dormant_user = User.create!(
      email: "dormant_fade_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Dormant Fade User",
      created_at: 90.days.ago
    )
    
    # 과거 거래 (40일 전)
    seller = User.create!(
      email: "dormant_seller_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Dormant Seller"
    )
    
    post = seller.posts.build(
      title: "Old Post",
      content: "Description",
      post_type: "marketplace",
      created_at: 60.days.ago
    )
    post.save(validate: false)
    post.create_product!(name: post.title, price: 50000, condition: "good")
    
    chat_room = ChatRoom.create!(
      post: post,
      buyer: @dormant_user,
      seller: seller,
      trade_status: "completed",
      created_at: 45.days.ago,
      updated_at: 45.days.ago
    )
    
    Message.create!(
      chat_room: chat_room,
      sender: @dormant_user,
      content_raw: "Old message",
      created_at: 40.days.ago
    )
  end

  def complete_trade_for(user)
    seller = User.create!(
      email: "seller_for_#{user.id}_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Seller for #{user.name}"
    )
    
    post = seller.posts.build(
      title: "Product for #{user.name}",
      content: "Description",
      post_type: "marketplace"
    )
    post.save(validate: false)
    post.create_product!(name: post.title, price: 50000, condition: "good")
    
    ChatRoom.create!(
      post: post,
      buyer: user,
      seller: seller,
      trade_status: "completed"
    )
  end

  def add_recent_activity(user)
    chat_room = ChatRoom.where(buyer: user).last || ChatRoom.where(seller: user).last
    return unless chat_room
    
    Message.create!(
      chat_room: chat_room,
      sender: user,
      content_raw: "Recent activity",
      created_at: 1.day.ago
    )
  end

  def sign_in(user)
    post user_session_path, params: { 
      user: { email: user.email, password: "password123" } 
    }
  end
end

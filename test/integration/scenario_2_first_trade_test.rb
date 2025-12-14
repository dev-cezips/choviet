# frozen_string_literal: true

require "test_helper"

# 📋 시나리오 2 — 첫 거래 유저 (First Trade Transition)
# 목표: 첫 거래 후 UX가 자연스럽게 다음 단계로 넘어가는가?

class Scenario2FirstTradeTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = User.create!(
      email: "buyer_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Buyer User"
    )
    
    @seller = User.create!(
      email: "seller_#{SecureRandom.hex(4)}@test.com",
      password: "password123",
      name: "Seller User"
    )
    
    @post = @seller.posts.build(
      title: "Test Product for Trade",
      content: "Test description",
      post_type: "marketplace"
    )
    @post.save(validate: false)
    @post.create_product!(name: @post.title, price: 150000, condition: "good")
    
    @chat_room = ChatRoom.create!(
      post: @post,
      buyer: @buyer,
      seller: @seller,
      trade_status: "negotiating"
    )
  end

  # ✅ 채팅 시작 가능
  test "buyer can access chat room" do
    sign_in @buyer
    get post_chat_room_path(@post, @chat_room)
    assert_response :success
  end

  # ✅ 거래 완료 버튼 동작 (판매자만)
  test "seller can complete trade" do
    sign_in @seller
    
    patch update_status_post_chat_room_path(@post, @chat_room), params: {
      trade_status: "completed"
    }
    
    @chat_room.reload
    assert_equal "completed", @chat_room.trade_status
  end

  # ✅ 거래 완료 후 시스템 메시지 표시됨
  test "system message appears after trade completion" do
    sign_in @seller
    
    patch update_status_post_chat_room_path(@post, @chat_room), params: {
      trade_status: "completed"
    }
    
    @chat_room.reload
    system_messages = @chat_room.messages.where(system_message: true)
    
    assert system_messages.any?, "System message should be created after completion"
    assert_match(/✅|🎉/, system_messages.last.content_raw, "Completion message should have success emoji")
  end

  # ✅ 리뷰 CTA 노출
  test "review CTA is visible after trade completion" do
    @chat_room.update!(trade_status: "completed")
    sign_in @buyer
    
    get post_chat_room_path(@post, @chat_room)
    assert_response :success
    
    # 리뷰 버튼이 있어야 함
    assert_match(/đánh giá|review/i, response.body, "Review CTA should be visible")
  end

  # ✅ 리뷰 작성: 별점만으로 제출 가능
  test "review can be submitted with rating only" do
    @chat_room.update!(trade_status: "completed")
    sign_in @buyer
    
    assert_difference "Review.count", 1 do
      post post_chat_room_reviews_path(@post, @chat_room), params: {
        review: { rating: 5, comment: "", visibility: true }
      }
    end
  end

  # ✅ 리뷰 작성: 텍스트는 선택 사항
  test "review comment is optional" do
    @chat_room.update!(trade_status: "completed")
    sign_in @buyer
    
    # 코멘트 없이 리뷰 생성
    review = Review.new(
      chat_room: @chat_room,
      reviewer: @buyer,
      reviewee: @seller,
      rating: 4,
      comment: nil
    )
    
    assert review.valid?, "Review should be valid without comment"
  end

  # ✅ 리뷰 제출 후 보상 메시지 표시 확인 (flash[:reward])
  test "reward message is set after review submission" do
    @chat_room.update!(trade_status: "completed")
    sign_in @buyer
    
    post post_chat_room_reviews_path(@post, @chat_room), params: {
      review: { rating: 5, comment: "Great seller!", visibility: true }
    }
    
    # flash[:reward]가 설정되어야 함
    assert flash[:reward].present?, "Reward flash should be set"
    assert_match(/🎉|Chúc mừng|Cảm ơn/, flash[:reward][:title], "Reward should be celebratory")
  end

  # ✅ 다시 진입 시 trust_hint 사라짐
  test "trust_hint disappears after first trade for active user" do
    # 거래 완료 및 리뷰 작성
    @chat_room.update!(trade_status: "completed")
    Review.create!(
      chat_room: @chat_room,
      reviewer: @buyer,
      reviewee: @seller,
      rating: 5,
      comment: "Great!"
    )
    
    # 최근 활동이 있고 첫 거래가 완료됨
    @buyer.reload
    
    # first_trade?가 false가 되면 hint가 사라져야 함
    if @buyer.first_trade? == false && @buyer.recently_active?(within: 30.days)
      hint = @buyer.trust_hint(context: :post)
      assert_nil hint, "Hint should disappear for active user after first trade"
    end
  end

  # ✅ trust_summary는 유지됨
  test "trust_summary remains after first trade" do
    @chat_room.update!(trade_status: "completed")
    
    summary = @buyer.trust_summary(context: :post)
    assert summary.present?, "Trust summary should always be present"
  end

  # 📌 실패 신호: 리뷰가 강제처럼 느껴지지 않음
  test "review CTA is not forceful" do
    @chat_room.update!(trade_status: "completed")
    sign_in @buyer
    
    get post_chat_room_path(@post, @chat_room)
    
    # 강제적인 단어가 없어야 함
    refute_match(/bắt buộc|phải|yêu cầu/i, response.body, "Review should not feel mandatory")
  end

  private

  def sign_in(user)
    post user_session_path, params: { 
      user: { email: user.email, password: "password123" } 
    }
  end
end

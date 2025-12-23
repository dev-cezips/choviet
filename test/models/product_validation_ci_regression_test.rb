require "test_helper"

# CI 회귀 방지: marketplace가 아닌 post에서 Product validation이 도는 문제를 방지
class ProductValidationCiRegressionTest < ActiveSupport::TestCase
  test "non-marketplace post with empty product fields should be valid" do
    # CI에서 실패했던 핵심 시나리오
    user = User.create!(
      email: "test@example.com",
      password: "password123"
    )

    # question post를 만들 때 빈 product attributes가 와도
    post = Post.new(
      user: user,
      title: "일반 질문입니다",
      content: "내용입니다 10자 이상",
      post_type: "question",
      product_attributes: {
        name: "",
        price: "",
        condition: ""
      }
    )

    # Post는 valid해야 하고 product는 생성되지 않아야 함
    assert post.valid?, "Question post should be valid even with empty product attributes"
    assert_nil post.product, "Product should not be created for non-marketplace posts"
  end

  test "marketplace post requires valid product" do
    user = User.create!(
      email: "test2@example.com",
      password: "password123"
    )

    # marketplace post를 만들 때 빈 product attributes가 오면
    post = Post.new(
      user: user,
      title: "판매합니다",
      content: "상세한 설명입니다 10자 이상",
      post_type: "marketplace",
      product_attributes: {
        name: "",
        price: "",
        condition: ""
      }
    )

    # Post는 invalid해야 함
    refute post.valid?, "Marketplace post should be invalid with empty product attributes"
  end

  test "post saves correctly with and without product" do
    user = User.create!(
      email: "test3@example.com",
      password: "password123"
    )

    # question post with product attributes should not create product
    question_post = Post.create!(
      user: user,
      title: "질문입니다",
      content: "내용입니다 10자 이상",
      post_type: "question",
      product_attributes: { name: "ignored", price: 1000 }
    )
    assert_nil question_post.product, "Question post should not have product"

    # marketplace post with valid product should create product
    marketplace_post = Post.create!(
      user: user,
      title: "판매합니다",
      content: "상세한 설명입니다 10자 이상",
      post_type: "marketplace",
      product_attributes: { name: "Valid Product", price: 1000, condition: "new_item" }
    )
    assert marketplace_post.product.present?, "Marketplace post should have product"
    assert_equal "Valid Product", marketplace_post.product.name
  end
end

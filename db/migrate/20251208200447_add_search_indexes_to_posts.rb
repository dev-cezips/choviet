class AddSearchIndexesToPosts < ActiveRecord::Migration[8.0]
  def change
    add_index :posts, :title
    add_index :posts, :content
    add_index :posts, :location_code
    add_index :posts, :status
    add_index :posts, :post_type # 카테고리별 필터용 추가
  end
end
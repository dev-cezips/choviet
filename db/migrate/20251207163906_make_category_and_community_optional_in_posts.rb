class MakeCategoryAndCommunityOptionalInPosts < ActiveRecord::Migration[8.0]
  def change
    change_column_null :posts, :category_id, true
    change_column_null :posts, :community_id, true
  end
end

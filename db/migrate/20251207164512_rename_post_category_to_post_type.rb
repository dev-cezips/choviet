class RenamePostCategoryToPostType < ActiveRecord::Migration[8.0]
  def change
    rename_column :posts, :category, :post_type
  end
end

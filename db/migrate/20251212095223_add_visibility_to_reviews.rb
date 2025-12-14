class AddVisibilityToReviews < ActiveRecord::Migration[8.0]
  def change
    add_column :reviews, :visibility, :boolean, default: true, null: false
  end
end

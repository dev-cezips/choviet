class MakePostIdNullableOnProducts < ActiveRecord::Migration[8.0]
  def change
    change_column_null :products, :post_id, true
  end
end

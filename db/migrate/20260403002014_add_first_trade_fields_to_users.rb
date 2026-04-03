class AddFirstTradeFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :first_sale_at, :datetime
    add_column :users, :first_purchase_at, :datetime
  end
end

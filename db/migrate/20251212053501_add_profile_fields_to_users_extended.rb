class AddProfileFieldsToUsersExtended < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :rating, :decimal, precision: 3, scale: 2, default: 0.0
    add_column :users, :trades_count, :integer, default: 0
    
    # Add indexes for performance
    add_index :users, :trades_count
    add_index :users, :rating
  end
end
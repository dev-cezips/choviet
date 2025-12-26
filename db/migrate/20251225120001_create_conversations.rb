class CreateConversations < ActiveRecord::Migration[8.0]
  def change
    create_table :conversations do |t|
      t.string :kind, null: false, default: "direct"
      t.bigint :user_a_id, null: false
      t.bigint :user_b_id, null: false
      
      t.timestamps
    end
    
    add_index :conversations, [:kind, :user_a_id, :user_b_id], unique: true
    add_foreign_key :conversations, :users, column: :user_a_id
    add_foreign_key :conversations, :users, column: :user_b_id
  end
end
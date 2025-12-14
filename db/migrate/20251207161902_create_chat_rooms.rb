class CreateChatRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :chat_rooms do |t|
      t.references :post, null: false, foreign_key: true
      t.integer :buyer_id
      t.integer :seller_id
      t.integer :status

      t.timestamps
    end
  end
end

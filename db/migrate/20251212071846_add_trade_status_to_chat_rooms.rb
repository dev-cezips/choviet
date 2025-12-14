class AddTradeStatusToChatRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :chat_rooms, :trade_status, :integer, default: 0, null: false
    add_index :chat_rooms, :trade_status
  end
end

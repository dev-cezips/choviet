class AddSystemMessageToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :system_message, :boolean, default: false, null: false
    add_index :messages, :system_message
  end
end

class CreateMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :messages do |t|
      t.references :chat_room, null: false, foreign_key: true
      t.integer :sender_id
      t.text :content_raw
      t.text :content_translated
      t.string :src_lang
      t.boolean :is_system
      t.datetime :read_at

      t.timestamps
    end
  end
end

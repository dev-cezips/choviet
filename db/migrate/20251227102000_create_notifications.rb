class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :actor, null: true, foreign_key: { to_table: :users }
      
      # Polymorphic association to the source
      t.string :notifiable_type
      t.bigint :notifiable_id
      
      t.integer :kind, null: false, default: 0
      t.string :title
      t.text :body
      t.json :data
      
      t.integer :status, null: false, default: 0
      t.datetime :delivered_at
      t.string :failure_reason
      
      t.timestamps
    end
    
    add_index :notifications, [:notifiable_type, :notifiable_id]
    add_index :notifications, :status
    add_index :notifications, [:recipient_id, :status]
    add_index :notifications, [:recipient_id, :kind, :created_at], name: 'index_notifications_for_listing'
  end
end
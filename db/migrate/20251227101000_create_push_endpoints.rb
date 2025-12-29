class CreatePushEndpoints < ActiveRecord::Migration[8.0]
  def change
    create_table :push_endpoints do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :platform, null: false, default: 0
      t.string :token, null: false
      t.string :device_id
      t.string :endpoint_url # For web push
      t.json :keys # For web push auth/p256dh keys
      t.boolean :active, null: false, default: true
      t.datetime :last_seen_at

      t.timestamps
    end

    add_index :push_endpoints, [ :user_id, :platform, :token ], unique: true, name: 'index_push_endpoints_unique'
    add_index :push_endpoints, :active
  end
end

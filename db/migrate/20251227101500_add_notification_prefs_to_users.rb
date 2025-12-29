class AddNotificationPrefsToUsers < ActiveRecord::Migration[8.0]
  def change
    # Notification preferences
    add_column :users, :notification_push_enabled, :boolean, default: true, null: false
    add_column :users, :notification_dm_enabled, :boolean, default: true, null: false
    add_column :users, :notification_email_enabled, :boolean, default: true, null: false
    
    # Indexes for filtering
    add_index :users, :notification_push_enabled
  end
end
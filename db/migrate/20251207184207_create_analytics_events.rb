class CreateAnalyticsEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :analytics_events do |t|
      t.references :user, null: true, foreign_key: true
      t.string :event_type, null: false
      t.json :properties, default: {}
      t.json :request_details, default: {}
      t.timestamps
    end

    add_index :analytics_events, :event_type
    add_index :analytics_events, :created_at
    add_index :analytics_events, [:event_type, :created_at]
  end
end
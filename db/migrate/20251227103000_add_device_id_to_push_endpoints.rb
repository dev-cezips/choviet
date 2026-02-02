class AddDeviceIdToPushEndpoints < ActiveRecord::Migration[8.0]
  def change
    # This migration is intentionally empty
    # device_id and last_seen_at are already in create_push_endpoints migration
  end
end

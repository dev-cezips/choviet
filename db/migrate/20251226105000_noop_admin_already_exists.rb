class NoopAdminAlreadyExists < ActiveRecord::Migration[8.0]
  def change
    # intentionally empty
    # admin column already added in 20251207184532_add_admin_to_users
  end
end

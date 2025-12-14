class AddLocationSettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :latitude, :float
    add_column :users, :longitude, :float
    add_column :users, :location_radius, :integer, default: 3
    add_reference :users, :location, foreign_key: true
    
    add_index :users, [:latitude, :longitude]
  end
end

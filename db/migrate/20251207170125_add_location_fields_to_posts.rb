class AddLocationFieldsToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :latitude, :float
    add_column :posts, :longitude, :float
    add_reference :posts, :location, foreign_key: true
    
    add_index :posts, [:latitude, :longitude]
  end
end

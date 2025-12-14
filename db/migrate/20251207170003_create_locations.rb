class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :name_ko
      t.string :name_vi
      t.string :code, null: false
      t.float :lat
      t.float :lng
      t.integer :parent_id
      t.integer :level, default: 0

      t.timestamps
    end

    add_index :locations, :code, unique: true
    add_index :locations, :parent_id
    add_foreign_key :locations, :locations, column: :parent_id
  end
end

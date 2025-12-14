class CreateTitles < ActiveRecord::Migration[8.0]
  def change
    create_table :titles do |t|
      t.string :name_vi
      t.string :key
      t.text :description
      t.string :category
      t.integer :level_required
      t.string :icon
      t.string :color

      t.timestamps
    end
    add_index :titles, :key, unique: true
    add_index :titles, :level_required
  end
end

class CreateCategories < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name_vi
      t.string :name_ko
      t.string :icon
      t.integer :position
      t.integer :parent_id
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :categories, :parent_id
    add_foreign_key :categories, :categories, column: :parent_id
  end
end

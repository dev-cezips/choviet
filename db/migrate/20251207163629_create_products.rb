class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.references :post, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.decimal :price
      t.integer :condition
      t.text :images
      t.boolean :sold
      t.string :currency

      t.timestamps
    end
  end
end

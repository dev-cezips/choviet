class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :category
      t.string :title
      t.text :content
      t.string :location_code
      t.boolean :target_korean
      t.integer :status

      t.timestamps
    end
  end
end

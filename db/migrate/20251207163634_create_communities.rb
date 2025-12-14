class CreateCommunities < ActiveRecord::Migration[8.0]
  def change
    create_table :communities do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.string :location_code
      t.integer :member_count
      t.boolean :is_private
      t.json :settings

      t.timestamps
    end
  end
end

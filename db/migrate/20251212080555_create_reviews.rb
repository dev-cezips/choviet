class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :chat_room, null: false, foreign_key: true
      t.references :reviewer, null: false, foreign_key: { to_table: :users }
      t.references :reviewee, null: false, foreign_key: { to_table: :users }
      t.integer :rating, null: false
      t.text :comment

      t.timestamps
    end

    # Add index to prevent duplicate reviews
    add_index :reviews, [ :chat_room_id, :reviewer_id ], unique: true
  end
end

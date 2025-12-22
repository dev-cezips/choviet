class CreateReviewReactions < ActiveRecord::Migration[8.0]
  def change
    create_table :review_reactions do |t|
      t.references :review, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :helpful, null: false, default: true

      t.timestamps
    end

    # Ensure one reaction per user per review
    add_index :review_reactions, [ :review_id, :user_id ], unique: true
  end
end

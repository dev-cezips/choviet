class CreateCommunityMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :community_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :community, null: false, foreign_key: true
      t.integer :role
      t.datetime :joined_at

      t.timestamps
    end
  end
end

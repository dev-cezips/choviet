class AddLocaleAndLocationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :locale, :string
    add_column :users, :location_code, :string
    add_column :users, :reputation_score, :integer
  end
end

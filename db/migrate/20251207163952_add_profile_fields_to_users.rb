class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :name, :string
    add_column :users, :phone, :string
    add_column :users, :bio, :text
    add_column :users, :verified, :boolean
    add_column :users, :avatar_url, :string
  end
end

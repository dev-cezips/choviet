class AddStoryToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :story, :text
  end
end

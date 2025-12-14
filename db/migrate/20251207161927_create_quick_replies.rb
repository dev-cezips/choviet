class CreateQuickReplies < ActiveRecord::Migration[8.0]
  def change
    create_table :quick_replies do |t|
      t.string :category
      t.string :content_vi
      t.string :content_ko

      t.timestamps
    end
  end
end

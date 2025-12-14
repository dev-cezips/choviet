class CreateReports < ActiveRecord::Migration[8.0]
  def change
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reported, polymorphic: true, null: false
      t.string :reason_code, null: false
      t.text :description
      t.string :status, default: 'pending', null: false

      t.timestamps
    end
    
    add_index :reports, [:reporter_id, :reported_id, :reported_type], unique: true, name: 'index_unique_report'
    add_index :reports, :status
    add_index :reports, :reason_code
  end
end

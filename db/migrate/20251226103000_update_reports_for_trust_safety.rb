class UpdateReportsForTrustSafety < ActiveRecord::Migration[8.0]
  def change
    # Rename columns to follow Rails polymorphic convention
    rename_column :reports, :reported_type, :reportable_type
    rename_column :reports, :reported_id, :reportable_id

    # Add new columns for admin functionality
    add_column :reports, :category, :string
    add_column :reports, :admin_note, :text
    add_column :reports, :handled_by_id, :bigint
    add_column :reports, :handled_at, :datetime

    # Add indexes (skip existing ones)
    add_index :reports, [ :reportable_type, :reportable_id ] unless index_exists?(:reports, [ :reportable_type, :reportable_id ])
    add_index :reports, :handled_by_id

    # Add foreign key for handled_by
    add_foreign_key :reports, :users, column: :handled_by_id
  end
end

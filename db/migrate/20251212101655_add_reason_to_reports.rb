class AddReasonToReports < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :reason, :string
  end
end

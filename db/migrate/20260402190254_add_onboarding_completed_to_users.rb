class AddOnboardingCompletedToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :onboarding_completed, :boolean, default: false, null: false

    # Mark existing users as having completed onboarding
    reversible do |dir|
      dir.up do
        execute "UPDATE users SET onboarding_completed = TRUE"
      end
    end
  end
end

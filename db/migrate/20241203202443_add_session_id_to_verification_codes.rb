class AddSessionIdToVerificationCodes < ActiveRecord::Migration[8.0]
  def change
    add_column :verification_codes, :session_id, :integer
    add_index :verification_codes, :session_id

    # Add a foreign key constraint to ensure verification codes are always connected to a session
    add_foreign_key :verification_codes, :sessions
  end
end

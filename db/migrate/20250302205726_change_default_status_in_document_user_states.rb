class ChangeDefaultStatusInDocumentUserStates < ActiveRecord::Migration[7.0]
  def up
    # First update all existing records with FEED status to INBOX
    execute <<-SQL
      UPDATE document_user_states#{' '}
      SET status = 'INBOX'#{' '}
      WHERE status = 'FEED'
    SQL

    # Then change the default for new records
    change_column_default :document_user_states, :status, from: "FEED", to: "INBOX"
  end

  def down
    # Change the default back to FEED
    change_column_default :document_user_states, :status, from: "INBOX", to: "FEED"

    # Update all records with INBOX status back to FEED
    execute <<-SQL
      UPDATE document_user_states#{' '}
      SET status = 'FEED'#{' '}
      WHERE status = 'INBOX'
    SQL
  end
end

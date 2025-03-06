class ChangeDocumentUserStateDefaultToLowercase < ActiveRecord::Migration[8.0]
  def up
    # First change the default for new rows
    change_column_default :document_user_states, :status, from: "INBOX", to: "inbox"

    # Then update all existing rows for all status types
    execute "UPDATE document_user_states SET status = 'inbox' WHERE status = 'INBOX'"
    execute "UPDATE document_user_states SET status = 'later' WHERE status = 'LATER'"
    execute "UPDATE document_user_states SET status = 'archive' WHERE status = 'ARCHIVE'"

    # This will handle any other uppercase statuses that might exist
    execute "UPDATE document_user_states SET status = LOWER(status) WHERE status = UPPER(status)"
  end

  def down
    change_column_default :document_user_states, :status, from: "inbox", to: "INBOX"

    # Convert back to uppercase if needed
    execute "UPDATE document_user_states SET status = 'INBOX' WHERE status = 'inbox'"
    execute "UPDATE document_user_states SET status = 'LATER' WHERE status = 'later'"
    execute "UPDATE document_user_states SET status = 'ARCHIVE' WHERE status = 'archive'"
  end
end

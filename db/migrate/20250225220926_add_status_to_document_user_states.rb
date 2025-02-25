class AddStatusToDocumentUserStates < ActiveRecord::Migration[8.0]
  def change
    add_column :document_user_states, :status, :string, default: "FEED", null: false
    add_index :document_user_states, :status
  end
end

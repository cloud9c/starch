class RenameDocumentUserStatesToDocumentStates < ActiveRecord::Migration[8.0]
  def change
    rename_table :document_user_states, :document_states
  end
end

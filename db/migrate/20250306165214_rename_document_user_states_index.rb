class RenameDocumentUserStatesIndex < ActiveRecord::Migration[8.0]
  def change
    rename_index :document_states,
                 "index_document_user_states_on_document_and_user",
                 "index_document_states_on_document_and_user"
  end
end

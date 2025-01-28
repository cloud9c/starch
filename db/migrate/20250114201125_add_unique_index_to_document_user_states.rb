class AddUniqueIndexToDocumentUserStates < ActiveRecord::Migration[8.0]
  def change
    add_index :document_user_states, [:document_id, :user_id], unique: true, 
      name: 'index_document_user_states_on_document_and_user'
  end
end

class AddDocumentStateIndexForDocumentIndex < ActiveRecord::Migration[8.0]
  def change
    add_index :document_states, [:user_id, :status, :read]
  end
end

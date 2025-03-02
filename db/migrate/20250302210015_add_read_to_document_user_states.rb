class AddReadToDocumentUserStates < ActiveRecord::Migration[8.0]
  def change
    add_column :document_user_states, :read, :boolean, default: false, null: false
    add_index :document_user_states, :read
  end
end

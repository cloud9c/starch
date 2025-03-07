class AddVisibleToDocumentStates < ActiveRecord::Migration[8.0]
  def change
    add_column :document_states, :visible, :boolean, default: true
    add_index :document_states, :visible
  end
end

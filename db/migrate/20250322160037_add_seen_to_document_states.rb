class AddSeenToDocumentStates < ActiveRecord::Migration[8.0]
  def change
    add_column :document_states, :seen, :boolean, default: false, null: false
  end
end

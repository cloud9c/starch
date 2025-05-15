class AddProgressToDocumentState < ActiveRecord::Migration[8.0]
  def change
    add_column :document_states, :progress, :float, default: 0
    add_column :document_states, :progress_raw, :float, default: 0
  end
end

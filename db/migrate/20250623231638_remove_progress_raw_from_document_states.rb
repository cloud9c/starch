class RemoveProgressRawFromDocumentStates < ActiveRecord::Migration[8.0]
  def change
    remove_column :document_states, :progress_raw, :float
  end
end

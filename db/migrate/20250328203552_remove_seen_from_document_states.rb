class RemoveSeenFromDocumentStates < ActiveRecord::Migration[8.0]
  def change
    remove_column :document_states, :seen
  end
end

class RemoveEntryIdFromDocuments < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :documents, :entries
    remove_index :documents, :entry_id
    remove_column :documents, :entry_id
  end
end

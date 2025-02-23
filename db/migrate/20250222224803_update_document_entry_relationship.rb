class UpdateDocumentEntryRelationship < ActiveRecord::Migration[8.0]
  def change
    # Remove the old foreign key from entries
    remove_column :entries, :document_id

    # Add entry_id to documents
    add_column :documents, :entry_id, :integer
    add_index :documents, :entry_id
  end
end

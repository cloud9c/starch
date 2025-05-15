class RemoveSourceTypeFromDocuments < ActiveRecord::Migration[8.0]
  def change
    remove_index :documents, :source_type
    remove_column :documents, :source_type, :integer
  end
end

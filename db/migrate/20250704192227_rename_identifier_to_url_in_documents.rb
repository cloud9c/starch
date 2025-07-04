class RenameIdentifierToUrlInDocuments < ActiveRecord::Migration[8.0]
  def change
    rename_column :documents, :identifier, :url
  end
end

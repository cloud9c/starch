class RenameUrlToIdentifierForDocuments < ActiveRecord::Migration[8.0]
  def change
    rename_column :documents, :url, :identifier
  end
end

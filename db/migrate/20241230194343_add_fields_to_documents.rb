class AddFieldsToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :content, :text
    remove_column :documents, :guid
  end
end

class AddParsedContentToDocuments < ActiveRecord::Migration[8.0]
  def up
    add_column :documents, :parsed_content, :text
  end

  def down
    remove_column :documents, :parsed_content
  end
end

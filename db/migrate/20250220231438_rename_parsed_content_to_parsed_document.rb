class RenameParsedContentToParsedDocument < ActiveRecord::Migration[8.0]
  def change
    rename_column :documents, :parsed_content, :parsed_data
    change_column :documents, :parsed_data, :jsonb
  end
end

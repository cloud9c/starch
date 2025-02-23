class RemoveParsedDataFromDocument < ActiveRecord::Migration[8.0]
  def change
    remove_column :documents, :parsed_data, :json
  end
end

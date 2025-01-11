class RemoveUrlIndexFromDocuments < ActiveRecord::Migration[8.0]
  def change
    remove_index :documents, :url
  end
end

class RemoveUserIdFromDocuments < ActiveRecord::Migration[8.0]
  def change
    remove_index :documents, name: "index_documents_on_user_id"
    remove_column :documents, :user_id, :integer
  end
end

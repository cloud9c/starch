class AddAuthorToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :author, :string
  end
end

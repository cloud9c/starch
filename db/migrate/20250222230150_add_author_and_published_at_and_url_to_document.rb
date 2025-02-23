class AddAuthorAndPublishedAtAndUrlToDocument < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :url, :string
    add_column :documents, :author, :string
    add_column :documents, :published_at, :datetime
  end
end

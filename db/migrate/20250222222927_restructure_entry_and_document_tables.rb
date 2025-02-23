class RestructureEntryAndDocumentTables < ActiveRecord::Migration[8.0]
  def change
    # Step 1: Add new columns to entries
    add_column :entries, :title, :string
    add_column :entries, :description, :text
    add_column :entries, :url, :string
    add_column :entries, :published_at, :datetime
    add_column :entries, :content, :text
    add_column :entries, :author, :string

    # Step 2: Migrate data from documents to entries
    execute <<-SQL
      UPDATE entries
      SET title = documents.title,
          description = documents.description,
          url = documents.url,
          published_at = documents.published_at,
          content = documents.content,
          author = documents.author
      FROM documents
      WHERE entries.document_id = documents.id
    SQL

    # Step 3: Remove columns from documents
    remove_column :documents, :title, :string
    remove_column :documents, :description, :text
    remove_column :documents, :url, :string
    remove_column :documents, :published_at, :datetime
    remove_column :documents, :content, :text
    remove_column :documents, :author, :string
  end
end

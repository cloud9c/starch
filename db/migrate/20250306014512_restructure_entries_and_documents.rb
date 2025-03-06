class RestructureEntriesAndDocuments < ActiveRecord::Migration[8.0]
  def change
    # Remove columns from entries that belong in documents
    remove_column :entries, :title, :string
    remove_column :entries, :description, :text
    remove_column :entries, :url, :string
    remove_column :entries, :published_at, :datetime
    remove_column :entries, :content, :text
    remove_column :entries, :author, :string

    # Add source_type to documents
    add_column :documents, :source_type, :string, null: false, default: 'rss_original'
    add_index :documents, :source_type

    # Set existing documents to rss_original
    Document.update_all(source_type: 'rss_original') if defined?(Document)
  end
end

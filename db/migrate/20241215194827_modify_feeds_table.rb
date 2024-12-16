class ModifyFeedsTable < ActiveRecord::Migration[8.0]
  def change
    # Rename columns
    rename_column :feeds, :url, :link
    rename_column :feeds, :published_at, :pubDate

    # Add guid column
    add_column :feeds, :guid, :string

    # Remove updated_at column
    remove_column :feeds, :updated_at

    # Since we're renaming the url column to link, we need to handle the index
    rename_index :feeds, 'index_feeds_on_url', 'index_feeds_on_link'
  end
end

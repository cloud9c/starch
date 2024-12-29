class RenamePubDateToPublishedAtInFeeds < ActiveRecord::Migration[8.0]
  def change
    rename_column :feeds, :pubDate, :published_at
  end
end

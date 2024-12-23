class RenameLinkToUrlInFeeds < ActiveRecord::Migration[8.0]
  def change
    rename_column :feeds, :link, :url
  end
end

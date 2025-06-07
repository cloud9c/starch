class RenameChannelToFeed < ActiveRecord::Migration[8.0]
  def change
    rename_table :channels, :feeds
    
    rename_column :entries, :channel_id, :feed_id
    rename_column :subscriptions, :channel_id, :feed_id
  end
end

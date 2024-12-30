class RemoveFeedFetchedAt < ActiveRecord::Migration[8.0]
  def change
    remove_column :channels, :feed_fetched_at
  end
end

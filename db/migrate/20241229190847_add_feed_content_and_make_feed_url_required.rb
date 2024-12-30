class AddFeedContentAndMakeFeedUrlRequired < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :feed_content, :text
    add_column :channels, :feed_fetched_at, :datetime
    change_column_null :channels, :feed_url, false
  end
end

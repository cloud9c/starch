class AddFeedUrlToChannels < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :feed_url, :string 
  end
end

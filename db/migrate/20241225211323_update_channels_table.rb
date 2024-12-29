class UpdateChannelsTable < ActiveRecord::Migration[8.0]
  def change
    add_index :channels, :feed_url, unique: true
    remove_index :channels, :origin
    remove_column :channels, :origin
  end
end

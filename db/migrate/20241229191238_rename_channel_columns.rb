class RenameChannelColumns < ActiveRecord::Migration[8.0]
  def change
    rename_column :channels, :feed_content, :xml
    rename_column :channels, :feed_url, :url
  end
end

class UnRenameChannelColumns < ActiveRecord::Migration[8.0]
  def change
    rename_column :channels, :xml, :feed_content
    rename_column :channels, :url, :feed_url
  end
end

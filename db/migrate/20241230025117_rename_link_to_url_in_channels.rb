class RenameLinkToUrlInChannels < ActiveRecord::Migration[8.0]
  def change
    rename_column :channels, :link, :url
  end
end

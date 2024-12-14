class RenameChannelItemsToPage < ActiveRecord::Migration[8.0]
  def change
    rename_table :channel_items, :pages
  end
end

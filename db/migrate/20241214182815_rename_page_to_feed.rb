class RenamePageToFeed < ActiveRecord::Migration[8.0]
  def change
    rename_table :pages, :feeds
  end
end

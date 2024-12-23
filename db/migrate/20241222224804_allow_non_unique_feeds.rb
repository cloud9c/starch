class AllowNonUniqueFeeds < ActiveRecord::Migration[8.0]
  def change
    remove_index :feeds, column: :link, if_exists: true
    add_index :feeds, :link
  end
end

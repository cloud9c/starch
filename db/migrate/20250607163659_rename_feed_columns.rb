class RenameFeedColumns < ActiveRecord::Migration[8.0]
  def change
    rename_column :feeds, :feed_content, :content
  end
end

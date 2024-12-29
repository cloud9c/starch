class RemoveLastScrapedAtInChannels < ActiveRecord::Migration[8.0]
  def change
    remove_column :channels, :last_scraped_at
  end
end

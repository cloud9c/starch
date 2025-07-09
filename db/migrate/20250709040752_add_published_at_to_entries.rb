class AddPublishedAtToEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :entries, :published_at, :datetime, null: false
    add_index :entries, :published_at
  end
end

class RemoveDefaultPolledAt < ActiveRecord::Migration[8.0]
  def up
    create_table :channels_new, force: :cascade do |t|
      t.string :title
      t.string :description
      t.string :icon
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.string :feed_url, null: false
      t.text :feed_content
      t.string :url
      # Intentionally omitting polled_at
    end

    # Add the index that exists in the original table
    add_index :channels_new, :feed_url, unique: true

    # Copy all data except polled_at
    execute <<-SQL
      INSERT INTO channels_new (
        id, title, description, icon, created_at, updated_at,
        feed_url, feed_content, url
      )
      SELECT#{' '}
        id, title, description, icon, created_at, updated_at,
        feed_url, feed_content, url
      FROM channels;
    SQL

    # Drop the old table (this will also drop its foreign keys)
    drop_table :channels

    # Rename the new table
    rename_table :channels_new, :channels

    # Recreate foreign keys
    add_foreign_key "documents", "channels"
    add_foreign_key "subscriptions", "channels"
  end

  def down
    add_column :channels, :polled_at, :datetime, null: false
  end
end

class RenameFoldersToTags < ActiveRecord::Migration[8.0]
  def up
    # Rename folders table to tags
    rename_table :folders, :tags

    # Create a join table for the many-to-many relationship
    create_table :subscriptions_tags do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps

      # Ensure unique combinations of subscription and tag
      t.index [ :subscription_id, :tag_id ], unique: true
    end

    # Remove the index and column directly
    remove_index :subscriptions, name: "index_subscriptions_on_folder_id" if index_exists?(:subscriptions, :folder_id)
    remove_column :subscriptions, :folder_id
  end

  def down
    # Add folder_id back to subscriptions
    add_column :subscriptions, :folder_id, :integer
    add_index :subscriptions, :folder_id
    add_foreign_key :subscriptions, :tags, column: :folder_id

    # Drop the join table
    drop_table :subscriptions_tags

    # Rename tags table back to folders
    rename_table :tags, :folders
  end
end

class AddEntriesTable < ActiveRecord::Migration[8.0]
  def up
    # Create new entries table
    create_table :entries do |t|
      t.references :channel, null: false, foreign_key: true
      t.string :stable_id, null: false    # stable identifier
      t.string :fingerprint, null: false  # content hash
      t.string :entry_id                  # original feed guid/id
      t.string :url
      t.string :title
      t.text :content
      t.string :author
      t.datetime :published_at
      t.timestamps

      t.index [ :channel_id, :stable_id ], unique: true
    end

    # Add entry reference to documents
    add_reference :documents, :entry, foreign_key: true, null: true

    # Migrate existing feed-based documents to use entries
    # You'd want to write a separate data migration for this

    # Remove channel connection from documents
    remove_reference :documents, :channel
    remove_index :documents, :channel_id if index_exists?(:documents, :channel_id)
  end

  def down
    # Add back channel reference to documents
    add_reference :documents, :channel, foreign_key: true

    # Migrate data back if needed

    # Remove entry reference from documents
    remove_reference :documents, :entry

    # Drop entries table
    drop_table :entries
  end
end

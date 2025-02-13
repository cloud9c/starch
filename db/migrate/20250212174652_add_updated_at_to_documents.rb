class AddUpdatedAtToDocuments < ActiveRecord::Migration[8.0]
  def up
    add_column :documents, :updated_at, :datetime

    # Backfill existing records with current timestamp
    execute <<-SQL
      UPDATE documents#{' '}
      SET updated_at = CURRENT_TIMESTAMP
    SQL

    # Make the column not nullable
    change_column_null :documents, :updated_at, false
  end

  def down
    remove_column :documents, :updated_at
  end
end

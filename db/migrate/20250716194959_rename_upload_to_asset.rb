class RenameUploadToAsset < ActiveRecord::Migration[8.0]
  def change
    # Rename the table
    rename_table :uploads, :assets

    # Update the polymorphic source_type references
    execute "UPDATE documents SET source_type = 'Asset' WHERE source_type = 'Upload'"
  end
end

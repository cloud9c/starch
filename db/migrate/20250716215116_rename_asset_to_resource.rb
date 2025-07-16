class RenameAssetToResource < ActiveRecord::Migration[8.0]
  def change
    # Rename the table
    rename_table :assets, :resources

    # Update the polymorphic source_type references
    execute "UPDATE documents SET source_type = 'Resource' WHERE source_type = 'Asset'"
  end
end

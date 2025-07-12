class RenameFileTypeToMimeTypeForUploads < ActiveRecord::Migration[8.0]
  def change
    rename_column :uploads, :file_type, :mime_type
  end
end

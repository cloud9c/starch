class AddFileTypeToUploads < ActiveRecord::Migration[8.0]
  def change
    add_column :uploads, :file_type, :integer, null: false
  end
end

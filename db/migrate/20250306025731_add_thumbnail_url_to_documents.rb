class AddThumbnailUrlToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :thumbnail_url, :string
  end
end

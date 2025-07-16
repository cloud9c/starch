class AddMetadataToAssets < ActiveRecord::Migration[8.0]
  def change
    add_column :assets, :metadata, :json
  end
end

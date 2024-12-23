class RenameImageToIconInChannels < ActiveRecord::Migration[8.0]
  def change
    rename_column :channels, :image, :icon
  end
end

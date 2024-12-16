class ModifyChannelsTable < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :link, :string
    remove_column :channels, :active, :boolean
  end
end

class RemoveWebSubColumnsFromChannels < ActiveRecord::Migration[8.0]
  def change
    remove_column :channels, :hub_url, :string
    remove_column :channels, :hub_verified_at, :datetime
  end
end

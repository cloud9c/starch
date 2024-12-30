class AddWebSubToChannels < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :hub_url, :string
    add_column :channels, :hub_secret, :string
    add_column :channels, :hub_verified_at, :datetime
  end
end

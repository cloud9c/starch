class RemoveHubSecretFromChannels < ActiveRecord::Migration[8.0]
  def change
    remove_column :channels, :hub_secret, :string
  end
end

class RemoveDeviceTokenFromSessions < ActiveRecord::Migration[8.0]
  def change
    remove_column :sessions, :device_token, :string
  end
end

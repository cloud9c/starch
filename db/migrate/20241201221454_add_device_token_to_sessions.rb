class AddDeviceTokenToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :device_token, :string
    add_index :sessions, :device_token, unique: true
  end
end

class AddConstraintsToChannelPolledAt < ActiveRecord::Migration[8.0]
  def change
    change_column :channels, :polled_at, :datetime, null: false, default: 0
  end
end

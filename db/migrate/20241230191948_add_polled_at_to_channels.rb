class AddPolledAtToChannels < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :polled_at, :datetime
  end
end

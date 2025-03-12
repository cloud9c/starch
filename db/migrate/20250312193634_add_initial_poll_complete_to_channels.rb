class AddInitialPollCompleteToChannels < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :initial_poll_complete, :boolean, default: false
  end
end

class AddLinkToChannels < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :link, :string
  end
end

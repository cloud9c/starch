class AddEtagToChannels < ActiveRecord::Migration[8.0]
  def change
    add_column :channels, :etag, :string
  end
end

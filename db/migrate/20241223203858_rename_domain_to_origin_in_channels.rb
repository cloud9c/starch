class RenameDomainToOriginInChannels < ActiveRecord::Migration[8.0]
  def change
    rename_column :channels, :domain, :origin
  end
end

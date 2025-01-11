class RenamePublicIdToStableIdInEntries < ActiveRecord::Migration[8.0]
  def change
    rename_column :entries, :public_id, :stable_id
  end
end

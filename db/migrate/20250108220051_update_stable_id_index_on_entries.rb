class UpdateStableIdIndexOnEntries < ActiveRecord::Migration[8.0]
  def change
    remove_index :entries, name: "index_entries_on_channel_id_and_stable_id"
    add_index :entries, :stable_id, unique: true
  end
end

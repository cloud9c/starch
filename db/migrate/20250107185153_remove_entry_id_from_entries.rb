class RemoveEntryIdFromEntries < ActiveRecord::Migration[8.0]
  def change
    remove_columns :entries,
      :entry_id
  end
end

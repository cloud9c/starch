class RemoveRedundancyInEntries < ActiveRecord::Migration[8.0]
  def change
    change_column_default :entries, :created_at, nil
    change_column_default :entries, :updated_at, nil
  end
end

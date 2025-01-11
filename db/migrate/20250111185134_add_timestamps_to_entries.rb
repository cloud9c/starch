class AddTimestampsToEntries < ActiveRecord::Migration[8.0]
  def change
    add_timestamps :entries, null: false, default: -> { 'CURRENT_TIMESTAMP' }
  end
end

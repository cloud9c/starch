class ConnectEntryToDocument < ActiveRecord::Migration[8.0]
  def change
    add_reference :entries, :document, null: false, foreign_key: true
  end
end

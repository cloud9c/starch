class MergeDocumentStateIntoDocument < ActiveRecord::Migration[8.0]
  def change
    add_reference :documents, :user, foreign_key: true, null: false
    add_column :documents, :status, :integer, null: false
    add_column :documents, :read, :boolean, default: false, null: false
    add_column :documents, :progress, :float, default: 0.0, null: false

    add_index :documents, [ :user_id, :status, :read ]

    drop_table :document_states
  end
end

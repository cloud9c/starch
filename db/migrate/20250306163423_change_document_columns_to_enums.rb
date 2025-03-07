class ChangeDocumentColumnsToEnums < ActiveRecord::Migration[8.0]
  def change
    # For documents table
    change_column :documents, :source_type, :integer, null: false

    # For document_states table
    change_column :document_states, :status, :integer, default: 0, null: false
  end
end

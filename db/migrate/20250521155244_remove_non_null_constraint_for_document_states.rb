class RemoveNonNullConstraintForDocumentStates < ActiveRecord::Migration[8.0]
  def change
    change_column_null :document_states, :status, true
    change_column_null :document_states, :read, true

    change_column_default :document_states, :status, nil
  end
end

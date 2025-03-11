class RemoveViewExtractedAndVisibleColumns < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :view_extracted, :boolean
    remove_column :document_states, :visible, :boolean
  end
end

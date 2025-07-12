class AddProgressIndicatorToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_column :documents, :progress_identifier, :text
  end
end

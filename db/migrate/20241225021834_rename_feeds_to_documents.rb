class RenameFeedsToDocuments < ActiveRecord::Migration[8.0]
  def change
    rename_table :feeds, :documents
  end
end

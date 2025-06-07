class ReplaceEntryIdWithSourceOnDocuments < ActiveRecord::Migration[8.0]
  def change
    remove_reference :documents, :entry
  end
end

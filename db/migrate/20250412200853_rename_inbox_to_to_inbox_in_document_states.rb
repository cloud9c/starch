class RenameInboxToToInboxInDocumentStates < ActiveRecord::Migration[8.0]
  def change
    rename_column :subscriptions, :inbox, :to_inbox
  end
end

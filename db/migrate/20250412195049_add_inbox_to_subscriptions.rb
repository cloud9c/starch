class AddInboxToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :inbox, :boolean, default: false, null: false
  end
end

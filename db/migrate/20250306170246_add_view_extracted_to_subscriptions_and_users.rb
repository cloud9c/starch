class AddViewExtractedToSubscriptionsAndUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :view_extracted, :boolean, default: false
    add_column :users, :view_extracted, :boolean, default: false
  end
end

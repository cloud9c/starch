class DeleteSubscriptionTagsAndTags < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :subscriptions_tags, :subscriptions
    remove_foreign_key :subscriptions_tags, :tags
    remove_foreign_key :tags, :users

    drop_table :subscriptions_tags
    drop_table :tags
  end
end

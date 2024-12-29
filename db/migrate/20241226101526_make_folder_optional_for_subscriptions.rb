class MakeFolderOptionalForSubscriptions < ActiveRecord::Migration[8.0]
  def change
    change_column_null :subscriptions, :folder_id, true
  end
end

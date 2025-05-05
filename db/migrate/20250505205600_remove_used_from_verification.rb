class RemoveUsedFromVerification < ActiveRecord::Migration[8.0]
  def change
    remove_column :verifications, :used
  end
end

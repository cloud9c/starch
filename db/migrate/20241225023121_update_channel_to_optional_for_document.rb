class UpdateChannelToOptionalForDocument < ActiveRecord::Migration[8.0]
  def change
    add_reference :documents, :user, null: false, foreign_key: true
    change_column_null :documents, :channel_id, true
  end
end

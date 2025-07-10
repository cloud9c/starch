class AddUserToUploads < ActiveRecord::Migration[8.0]
  def change
    add_reference :uploads, :user, null: false, foreign_key: true
  end
end

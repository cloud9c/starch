class RenameEmailAddressToUsername < ActiveRecord::Migration[8.0]
  def change
    rename_column :email_addresses, :email_address, :username
  end
end

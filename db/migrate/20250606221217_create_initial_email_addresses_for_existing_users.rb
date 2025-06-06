class CreateInitialEmailAddressesForExistingUsers < ActiveRecord::Migration[8.0]
  def change
   User.find_each do |user|
     next if user.email_addresses.exists?

     user.email_addresses.create!
   end
  end
end

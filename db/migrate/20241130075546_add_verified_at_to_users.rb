class AddVerifiedAtToUsers < ActiveRecord::Migration[7.1]
 def change
   add_column :users, :verified_at, :datetime
   add_index :users, :verified_at
 end
end

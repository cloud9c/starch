class CreateEmailAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :email_addresses do |t|
      t.string :email_address
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    add_index :email_addresses, :email_address, unique: true
  end
end

class CreateEmailSenders < ActiveRecord::Migration[8.0]
  def change
    create_table :email_senders do |t|
      t.string :display_name
      t.string :email_address
      t.string :icon

      t.timestamps
    end

    add_index :email_senders, :email_address, unique: true
  end
end

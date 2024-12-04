class AddMagicLinkTokenToVerificationCodes < ActiveRecord::Migration[8.0]
  def change
    add_column :verification_codes, :magic_link_token, :string
    add_index :verification_codes, :magic_link_token, unique: true
  end
end

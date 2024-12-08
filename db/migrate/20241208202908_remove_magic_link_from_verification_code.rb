class RemoveMagicLinkFromVerificationCode < ActiveRecord::Migration[8.0]
  def change
    remove_column :verification_codes, :magic_link_token, :string
    remove_index :verification_codes, :magic_link_token if index_exists?(:verification_codes, :magic_link_token)
  end
end

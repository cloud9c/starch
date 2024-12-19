class RenameVerificationCodeToVerification < ActiveRecord::Migration[8.0]
  def change
    rename_table :verification_codes, :verifications
  end
end

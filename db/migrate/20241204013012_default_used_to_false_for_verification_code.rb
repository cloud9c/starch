class DefaultUsedToFalseForVerificationCode < ActiveRecord::Migration[8.0]
  def change
    change_column_default :verification_codes, :used, false
  end
end

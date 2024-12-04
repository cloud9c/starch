class CreateVerificationCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :verification_codes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :code
      t.datetime :expires_at
      t.boolean :used

      t.timestamps
    end
  end
end

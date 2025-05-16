class CreateWebauthnCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :webauthn_credentials do |t|
      t.string :external_id, null: false
      t.string :public_key, null: false
      t.string :nickname
      t.bigint :sign_count, null: false, default: 0
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
    
    add_index :webauthn_credentials, :external_id, unique: true
    
    add_column :users, :webauthn_id, :string
  end
end

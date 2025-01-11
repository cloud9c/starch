class CreateDocumentUserStates < ActiveRecord::Migration[8.0]
  def change
    create_table :document_user_states do |t|
      t.references :user, null: false, foreign_key: true
      t.references :document, null: false, foreign_key: true
      t.timestamps
    end
  end
end

class CreateFoldersAndSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :folders do |t|
      t.string :name
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    create_table :subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :channel, null: false, foreign_key: true
      t.references :folder, null: false, foreign_key: true
      t.timestamps
    end

    add_index :subscriptions, [ :user_id, :channel_id ], unique: true
  end
end

class CreateChannelItems < ActiveRecord::Migration[8.0]
  def change
    create_table :channel_items do |t|
      t.string :title
      t.text :description
      t.string :url, null: false
      t.datetime :published_at
      
      t.references :channel, null: false, foreign_key: true

      t.timestamps
      t.index :url, unique: true
    end
  end
end

class CreateChannels < ActiveRecord::Migration[8.0]
 def change
   create_table :channels do |t|
     t.string :domain, null: false, index: { unique: true }
     t.string :title
     t.string :description
     t.string :image
     t.boolean :active, default: true
     t.datetime :last_scraped_at
     t.timestamps
   end
 end
end

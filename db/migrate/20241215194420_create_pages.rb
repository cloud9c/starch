class CreatePages < ActiveRecord::Migration[8.0]
  def change
    create_table :pages do |t|
      t.string :description
      t.string :link
      t.datetime :published_at
      t.timestamps
    end
  end
end

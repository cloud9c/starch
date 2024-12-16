class AddUniqueIndexToPages < ActiveRecord::Migration[8.0]
  def change
    add_index :pages, :link, unique: true
  end
end

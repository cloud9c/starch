class AddContentToPages < ActiveRecord::Migration[8.0]
  def change
    add_column :pages, :content, :text
  end
end

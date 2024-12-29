class DeletePagesTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :pages
  end
end

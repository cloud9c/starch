class RemoveTimestampsFromPages < ActiveRecord::Migration[8.0]
  def change
    remove_column :pages, :created_at
    remove_column :pages, :updated_at
  end
end

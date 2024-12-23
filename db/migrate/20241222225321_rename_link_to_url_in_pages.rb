class RenameLinkToUrlInPages < ActiveRecord::Migration[8.0]
  def change
    rename_column :pages, :link, :url
  end
end

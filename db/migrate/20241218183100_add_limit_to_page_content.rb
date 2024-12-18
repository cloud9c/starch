class AddLimitToPageContent < ActiveRecord::Migration[8.0]
  def change
    change_column :pages, :content, :text, limit: 100_000
  end
end

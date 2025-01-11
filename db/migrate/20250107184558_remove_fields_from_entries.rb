class RemoveFieldsFromEntries < ActiveRecord::Migration[8.0]
  def change
    remove_columns :entries,
      :url,
      :title,
      :content,
      :author,
      :published_at,
      :created_at,
      :updated_at
  end
end

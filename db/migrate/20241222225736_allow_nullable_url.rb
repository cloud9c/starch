class AllowNullableUrl < ActiveRecord::Migration[8.0]
  def change
    change_column_null :feeds, :url, true
  end
end

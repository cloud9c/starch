class RequireUserInSession < ActiveRecord::Migration[8.0]
  def change
    reversible do |dir|
      dir.up do
        execute("DELETE FROM sessions WHERE user_id IS NULL")
      end
    end

    change_column_null :sessions, :user_id, false
  end
end

class AddPolymorphicSourceToDocuments < ActiveRecord::Migration[8.0]
  def change
    add_reference :documents, :source, polymorphic: true, null: true

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE documents#{' '}
          SET source_type = 'Entry', source_id = entry_id#{' '}
          WHERE entry_id IS NOT NULL
        SQL
      end

      dir.down do
        execute <<-SQL
          UPDATE documents#{' '}
          SET entry_id = source_id#{' '}
          WHERE source_type = 'Entry'
        SQL
      end
    end
  end
end

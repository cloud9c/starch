class RemoveFingerprintFromEntry < ActiveRecord::Migration[8.0]
  def change
    remove_column :entries, :fingerprint
  end
end

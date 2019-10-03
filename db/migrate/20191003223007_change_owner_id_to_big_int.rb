class ChangeOwnerIdToBigInt < ActiveRecord::Migration[5.2]
  def change
    change_column :tasks, :owner_id, :bigint, null: false, unique: true
  end
end

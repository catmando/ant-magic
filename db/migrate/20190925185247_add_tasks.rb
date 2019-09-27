class AddTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :tasks do |t|
      t.string     :title
      t.boolean    :completed, null: false, default: false
      t.references :owner

      t.timestamps
    end
  end
end

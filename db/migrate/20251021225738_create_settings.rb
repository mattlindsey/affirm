class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings, if_not_exists: true do |t|
      t.string :name

      t.timestamps
    end
  end
end

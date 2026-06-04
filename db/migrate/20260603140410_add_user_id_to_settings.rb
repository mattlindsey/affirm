class AddUserIdToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :user_id, :integer
    add_index :settings, :user_id, unique: true
  end
end

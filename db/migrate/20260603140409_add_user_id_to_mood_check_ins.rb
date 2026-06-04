class AddUserIdToMoodCheckIns < ActiveRecord::Migration[8.1]
  def change
    add_column :mood_check_ins, :user_id, :integer
    add_index :mood_check_ins, :user_id
  end
end

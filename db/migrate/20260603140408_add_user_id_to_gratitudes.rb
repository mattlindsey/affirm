class AddUserIdToGratitudes < ActiveRecord::Migration[8.1]
  def change
    add_column :gratitudes, :user_id, :integer
    add_index :gratitudes, :user_id
  end
end

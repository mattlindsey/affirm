class AddUserIdToAffirmations < ActiveRecord::Migration[8.1]
  def change
    add_column :affirmations, :user_id, :integer
    add_index :affirmations, :user_id
  end
end

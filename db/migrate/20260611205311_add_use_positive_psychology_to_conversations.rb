class AddUsePositivePsychologyToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :use_positive_psychology, :boolean, default: false, null: false
  end
end

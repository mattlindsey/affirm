class AddForeignKeysForUserContent < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :affirmations,   :users, on_delete: :cascade
    add_foreign_key :gratitudes,     :users, on_delete: :cascade
    add_foreign_key :mood_check_ins, :users, on_delete: :cascade
    add_foreign_key :settings,       :users, on_delete: :cascade
    add_foreign_key :reflections,    :users, on_delete: :cascade
  end
end

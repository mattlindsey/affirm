class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: { on_delete: :cascade }
      t.string :role, null: false
      t.text :content, null: false

      t.timestamps
    end
  end
end

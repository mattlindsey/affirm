class CreateReflections < ActiveRecord::Migration[8.1]
  def change
    create_table :reflections do |t|
      t.references :user, null: true
      t.references :mood_check_in, null: false, foreign_key: true
      t.text :content

      t.timestamps
    end
  end
end

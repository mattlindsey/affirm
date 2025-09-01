class CreateMoodCheckIns < ActiveRecord::Migration[8.0]
  def change
    create_table :mood_check_ins do |t|
      t.integer :mood_level, null: false
      t.text :notes

      t.timestamps
    end

    add_index :mood_check_ins, :created_at
  end
end

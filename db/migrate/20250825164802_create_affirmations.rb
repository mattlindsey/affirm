class CreateAffirmations < ActiveRecord::Migration[8.0]
  def change
    create_table :affirmations do |t|
      t.string :content

      t.timestamps
    end
  end
end

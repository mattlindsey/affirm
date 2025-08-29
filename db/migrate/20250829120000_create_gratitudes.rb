class CreateGratitudes < ActiveRecord::Migration[7.2]
  def change
    create_table :gratitudes do |t|
      t.text :content, null: false

      t.timestamps
    end
  end
end

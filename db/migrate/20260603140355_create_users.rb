class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest
      t.string :google_uid
      t.string :name

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :google_uid, unique: true,
              where: "google_uid IS NOT NULL",
              name: "index_users_on_google_uid_not_null"
  end
end

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_10_29_170633) do
  create_table "affirmations", force: :cascade do |t|
    t.string "content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "gratitudes", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "mood_check_ins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "mood_level", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_mood_check_ins_on_created_at"
  end

  create_table "reflections", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.integer "mood_check_in_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["mood_check_in_id"], name: "index_reflections_on_mood_check_in_id"
    t.index ["user_id"], name: "index_reflections_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "reflections", "mood_check_ins"
end

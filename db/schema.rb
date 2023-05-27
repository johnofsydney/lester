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

ActiveRecord::Schema[7.0].define(version: 2023_05_11_121828) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "memberships", force: :cascade do |t|
    t.string "member_type", null: false
    t.bigint "member_id", null: false
    t.bigint "owner_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.text "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["member_type", "member_id"], name: "index_memberships_on_member"
    t.index ["owner_id"], name: "index_memberships_on_owner_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transfers", force: :cascade do |t|
    t.string "giver_type", null: false
    t.bigint "giver_id", null: false
    t.string "taker_type", null: false
    t.bigint "taker_id", null: false
    t.date "effective_date", null: false
    t.integer "amount", default: 0, null: false
    t.text "transfer_type", null: false
    t.text "evidence"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["giver_type", "giver_id"], name: "index_transfers_on_giver"
    t.index ["taker_type", "taker_id"], name: "index_transfers_on_taker"
  end

  add_foreign_key "memberships", "groups", column: "owner_id"
end

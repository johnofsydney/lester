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

ActiveRecord::Schema[7.0].define(version: 2023_05_27_042114) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "affiliations", force: :cascade do |t|
    t.bigint "owning_group_id", null: false
    t.bigint "sub_group_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.text "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owning_group_id"], name: "index_affiliations_on_owning_group_id"
    t.index ["sub_group_id"], name: "index_affiliations_on_sub_group_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "person_id", null: false
    t.bigint "group_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["person_id"], name: "index_memberships_on_person_id"
  end

  create_table "people", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "transfers", force: :cascade do |t|
    t.string "giver_type"
    t.bigint "giver_id"
    t.bigint "taker_id", null: false
    t.integer "amount"
    t.text "evidence"
    t.text "transfer_type"
    t.date "effective_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["giver_type", "giver_id"], name: "index_transfers_on_giver"
    t.index ["taker_id"], name: "index_transfers_on_taker_id"
  end

  add_foreign_key "affiliations", "groups", column: "owning_group_id"
  add_foreign_key "affiliations", "groups", column: "sub_group_id"
  add_foreign_key "memberships", "groups"
  add_foreign_key "memberships", "people"
  add_foreign_key "transfers", "groups", column: "taker_id"
end

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

ActiveRecord::Schema[8.0].define(version: 2026_02_17_235033) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string "namespace"
    t.text "body"
    t.string "resource_type"
    t.bigint "resource_id"
    t.string "author_type"
    t.bigint "author_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author"
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace"
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource"
  end

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "api_logs", force: :cascade do |t|
    t.string "endpoint"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "contract_backfills", force: :cascade do |t|
    t.date "last_processed_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["last_processed_date"], name: "index_contract_backfills_on_last_processed_date", unique: true
  end

  create_table "fine_grained_transaction_categories", force: :cascade do |t|
    t.string "name"
    t.bigint "major_transaction_category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["major_transaction_category_id"], name: "idx_on_major_transaction_category_id_558fd27f86"
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_flipper_features_on_key", unique: true
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string "feature_key", null: false
    t.string "key", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feature_key", "key", "value"], name: "index_flipper_gates_on_feature_key_and_key_and_value", unique: true
  end

  create_table "groups", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "category", default: false
    t.json "cached_data", default: {}
    t.string "business_number"
    t.date "last_refreshed"
    t.integer "nodes_count_cached"
    t.datetime "nodes_count_cached_at"
    t.index "lower((name)::text)", name: "index_groups_on_lower_name", unique: true
    t.index ["business_number"], name: "index_groups_on_business_number", unique: true
    t.index ["category"], name: "index_groups_on_category"
    t.index ["name"], name: "index_groups_on_name"
  end

  create_table "individual_transactions", force: :cascade do |t|
    t.bigint "transfer_id"
    t.float "amount"
    t.text "evidence"
    t.string "transaction_type"
    t.date "effective_date"
    t.string "external_id"
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "contract_id"
    t.string "amendment_id"
    t.string "category"
    t.string "giver_type"
    t.bigint "giver_id"
    t.string "taker_type"
    t.bigint "taker_id"
    t.bigint "fine_grained_transaction_category_id"
    t.index ["contract_id"], name: "index_individual_transactions_on_contract_id"
    t.index ["effective_date"], name: "index_individual_transactions_on_effective_date"
    t.index ["external_id"], name: "index_individual_transactions_on_external_id"
    t.index ["fine_grained_transaction_category_id"], name: "idx_on_fine_grained_transaction_category_id_662409c654"
    t.index ["giver_type", "giver_id"], name: "index_individual_transactions_on_giver"
    t.index ["taker_type", "taker_id"], name: "index_individual_transactions_on_taker"
    t.index ["transfer_id"], name: "index_individual_transactions_on_transfer_id"
  end

  create_table "leadership_websites", force: :cascade do |t|
    t.bigint "group_id"
    t.text "url"
    t.text "name_selector"
    t.text "title_selector"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "people_card_selector"
    t.date "reviewed_at"
    t.index ["group_id"], name: "index_leadership_websites_on_group_id"
  end

  create_table "major_transaction_categories", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "memberships", force: :cascade do |t|
    t.string "member_type", null: false
    t.bigint "member_id", null: false
    t.bigint "group_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "evidence"
    t.index ["end_date"], name: "index_memberships_on_end_date"
    t.index ["group_id", "member_type", "member_id"], name: "index_memberships_on_group_and_member"
    t.index ["group_id"], name: "index_memberships_on_group_id"
    t.index ["member_type", "member_id"], name: "index_memberships_on_member"
    t.index ["start_date", "end_date"], name: "index_memberships_on_start_date_and_end_date"
    t.index ["start_date"], name: "index_memberships_on_start_date"
  end

  create_table "people", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "cached_data", default: {}
    t.string "linkedin_url"
    t.date "linkedin_ingested"
    t.integer "nodes_count_cached"
    t.datetime "nodes_count_cached_at"
    t.index "lower((name)::text)", name: "index_people_on_lower_name", unique: true
    t.index ["name"], name: "index_people_on_name"
  end

  create_table "pg_search_documents", force: :cascade do |t|
    t.text "content"
    t.string "searchable_type"
    t.bigint "searchable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["searchable_type", "searchable_id"], name: "index_pg_search_documents_on_searchable"
  end

  create_table "positions", force: :cascade do |t|
    t.bigint "membership_id", null: false
    t.date "start_date"
    t.date "end_date"
    t.string "title", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "evidence"
    t.index ["membership_id"], name: "index_positions_on_membership_id"
  end

  create_table "suggestions", force: :cascade do |t|
    t.string "headline", null: false
    t.text "description"
    t.string "evidence", null: false
    t.string "suggested_by"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "trading_names", force: :cascade do |t|
    t.string "owner_type", null: false
    t.bigint "owner_id", null: false
    t.text "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_trading_names_on_name"
    t.index ["owner_type", "owner_id", "name"], name: "index_trading_names_on_owner_and_name", unique: true
    t.index ["owner_type", "owner_id"], name: "index_trading_names_on_owner"
  end

  create_table "transfers", force: :cascade do |t|
    t.string "giver_type"
    t.bigint "giver_id"
    t.string "taker_type"
    t.bigint "taker_id"
    t.float "amount", default: 0.0, null: false
    t.text "evidence"
    t.text "transfer_type"
    t.date "effective_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "data", default: {}
    t.text "external_id"
    t.index ["effective_date"], name: "index_transfers_on_effective_date"
    t.index ["external_id"], name: "index_transfers_on_external_id"
    t.index ["giver_type", "giver_id"], name: "index_transfers_on_giver"
    t.index ["taker_type", "taker_id"], name: "index_transfers_on_taker"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "fine_grained_transaction_categories", "major_transaction_categories"
  add_foreign_key "individual_transactions", "fine_grained_transaction_categories"
  add_foreign_key "individual_transactions", "transfers"
  add_foreign_key "memberships", "groups"
  add_foreign_key "positions", "memberships"
end

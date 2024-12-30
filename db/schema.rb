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

ActiveRecord::Schema[8.0].define(version: 2024_12_30_025117) do
  create_table "channels", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "icon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "feed_url", null: false
    t.text "feed_content"
    t.string "url"
    t.string "hub_url"
    t.string "hub_secret"
    t.datetime "hub_verified_at"
    t.index ["feed_url"], name: "index_channels_on_feed_url", unique: true
  end

  create_table "documents", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "url"
    t.datetime "published_at"
    t.integer "channel_id"
    t.datetime "created_at", null: false
    t.string "guid"
    t.integer "user_id", null: false
    t.index ["channel_id"], name: "index_documents_on_channel_id"
    t.index ["url"], name: "index_documents_on_url"
    t.index ["user_id"], name: "index_documents_on_user_id"
  end

  create_table "folders", force: :cascade do |t|
    t.string "name"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_folders_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "channel_id", null: false
    t.integer "folder_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_subscriptions_on_channel_id"
    t.index ["folder_id"], name: "index_subscriptions_on_folder_id"
    t.index ["user_id", "channel_id"], name: "index_subscriptions_on_user_id_and_channel_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["verified_at"], name: "index_users_on_verified_at"
  end

  create_table "verifications", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "code"
    t.datetime "expires_at"
    t.boolean "used", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "session_id"
    t.index ["session_id"], name: "index_verifications_on_session_id"
    t.index ["user_id"], name: "index_verifications_on_user_id"
  end

  add_foreign_key "documents", "channels"
  add_foreign_key "documents", "users"
  add_foreign_key "folders", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscriptions", "channels"
  add_foreign_key "subscriptions", "folders"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "verifications", "sessions"
  add_foreign_key "verifications", "users"
end

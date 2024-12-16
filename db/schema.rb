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

ActiveRecord::Schema[8.0].define(version: 2024_12_16_004841) do
  create_table "channels", force: :cascade do |t|
    t.string "domain", null: false
    t.string "title"
    t.string "description"
    t.string "image"
    t.datetime "last_scraped_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain"], name: "index_channels_on_domain", unique: true
  end

  create_table "feeds", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.string "link", null: false
    t.datetime "pubDate"
    t.integer "channel_id", null: false
    t.datetime "created_at", null: false
    t.string "guid"
    t.index ["channel_id"], name: "index_feeds_on_channel_id"
    t.index ["link"], name: "index_feeds_on_link", unique: true
  end

  create_table "pages", force: :cascade do |t|
    t.string "description"
    t.string "link"
    t.datetime "published_at"
    t.integer "channel_id", null: false
    t.string "title"
    t.index ["channel_id"], name: "index_pages_on_channel_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["verified_at"], name: "index_users_on_verified_at"
  end

  create_table "verification_codes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "code"
    t.datetime "expires_at"
    t.boolean "used", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "session_id"
    t.index ["session_id"], name: "index_verification_codes_on_session_id"
    t.index ["user_id"], name: "index_verification_codes_on_user_id"
  end

  add_foreign_key "feeds", "channels"
  add_foreign_key "pages", "channels"
  add_foreign_key "sessions", "users"
  add_foreign_key "verification_codes", "sessions"
  add_foreign_key "verification_codes", "users"
end

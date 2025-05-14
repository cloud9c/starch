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

ActiveRecord::Schema[8.0].define(version: 2025_05_13_220009) do
  create_table "channels", force: :cascade do |t|
    t.string "title"
    t.string "description"
    t.string "icon"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "feed_url", null: false
    t.text "feed_content"
    t.string "url"
    t.datetime "polled_at"
    t.string "etag"
    t.boolean "initial_poll_complete", default: false
    t.index ["feed_url"], name: "index_channels_on_feed_url", unique: true
  end

  create_table "document_states", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "document_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.boolean "read", default: false, null: false
    t.index ["document_id", "user_id"], name: "index_document_states_on_document_and_user", unique: true
    t.index ["document_id"], name: "index_document_states_on_document_id"
    t.index ["read"], name: "index_document_states_on_read"
    t.index ["status"], name: "index_document_states_on_status"
    t.index ["user_id", "status", "read"], name: "index_document_states_on_user_id_and_status_and_read"
    t.index ["user_id"], name: "index_document_states_on_user_id"
  end

  create_table "documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "entry_id"
    t.string "title"
    t.text "description"
    t.text "content"
    t.string "url"
    t.string "author"
    t.datetime "published_at"
    t.integer "source_type", null: false
    t.string "thumbnail_url"
    t.index ["entry_id"], name: "index_documents_on_entry_id"
    t.index ["source_type"], name: "index_documents_on_source_type"
  end

  create_table "entries", force: :cascade do |t|
    t.integer "channel_id", null: false
    t.string "stable_id", null: false
    t.string "fingerprint", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["channel_id"], name: "index_entries_on_channel_id"
    t.index ["stable_id"], name: "index_entries_on_stable_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "channel_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "view_extracted", default: false
    t.boolean "to_inbox", default: false, null: false
    t.index ["channel_id"], name: "index_subscriptions_on_channel_id"
    t.index ["user_id", "channel_id"], name: "index_subscriptions_on_user_id_and_channel_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "verified_at"
    t.boolean "paid", default: false
    t.string "stripe_customer_id"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id"
    t.index ["verified_at"], name: "index_users_on_verified_at"
  end

  add_foreign_key "document_states", "documents"
  add_foreign_key "document_states", "users"
  add_foreign_key "entries", "channels"
  add_foreign_key "sessions", "users"
  add_foreign_key "subscriptions", "channels"
  add_foreign_key "subscriptions", "channels"
  add_foreign_key "subscriptions", "users"
end

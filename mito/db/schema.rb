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

ActiveRecord::Schema[8.0].define(version: 2025_08_04_070617) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "anonymous_chats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "session_id"
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "anonymous_messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "anonymous_chat_id", null: false
    t.text "content"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["anonymous_chat_id"], name: "index_anonymous_messages_on_anonymous_chat_id"
  end

  create_table "api_usages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "message_id", null: false
    t.string "model", limit: 50, null: false
    t.integer "prompt_tokens", null: false
    t.integer "completion_tokens", null: false
    t.integer "total_tokens", null: false
    t.decimal "cost_usd", precision: 10, scale: 6, null: false
    t.datetime "request_timestamp", precision: nil, null: false
    t.integer "response_time_ms"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cost_usd"], name: "index_api_usages_on_cost_usd"
    t.index ["message_id"], name: "index_api_usages_on_message_id"
    t.index ["model"], name: "index_api_usages_on_model"
    t.index ["request_timestamp"], name: "index_api_usages_on_request_timestamp"
  end

  create_table "chats", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_chats_on_user_id"
  end

  create_table "message_sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "source_id", null: false
    t.string "messageable_type", null: false
    t.uuid "messageable_id", null: false
    t.decimal "relevance_score", precision: 4, scale: 3, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["messageable_type", "messageable_id"], name: "index_message_sources_on_messageable"
    t.index ["messageable_type", "messageable_id"], name: "index_message_sources_on_messageable_type_and_messageable_id"
    t.index ["relevance_score"], name: "index_message_sources_on_relevance_score"
    t.index ["source_id", "messageable_type", "messageable_id"], name: "index_message_sources_uniqueness", unique: true
    t.index ["source_id"], name: "index_message_sources_on_source_id"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "chat_id", null: false
    t.text "content"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "variant"
    t.uuid "comparison_group_id"
    t.float "processing_time"
    t.decimal "total_cost_usd", precision: 10, scale: 6
    t.jsonb "token_usage"
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["comparison_group_id"], name: "index_messages_on_comparison_group_id"
    t.index ["token_usage"], name: "index_messages_on_token_usage", using: :gin
    t.index ["total_cost_usd"], name: "index_messages_on_total_cost_usd"
    t.index ["variant"], name: "index_messages_on_variant"
  end

  create_table "model_pricings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "model", limit: 50, null: false
    t.decimal "input_cost_per_1k_tokens", precision: 10, scale: 6, null: false
    t.decimal "output_cost_per_1k_tokens", precision: 10, scale: 6, null: false
    t.date "effective_date", null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["effective_date"], name: "index_model_pricings_on_effective_date"
    t.index ["is_active"], name: "index_model_pricings_on_is_active"
    t.index ["model", "is_active"], name: "index_model_pricings_on_model_and_is_active", unique: true, where: "(is_active = true)"
    t.index ["model"], name: "index_model_pricings_on_model"
  end

  create_table "sources", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title", null: false
    t.string "url", null: false
    t.text "excerpt"
    t.text "chunk_text"
    t.integer "chunk_size"
    t.string "document_id"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_sources_on_document_id"
    t.index ["title"], name: "index_sources_on_title"
    t.index ["url"], name: "index_sources_on_url", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "admin", default: false, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "anonymous_messages", "anonymous_chats"
  add_foreign_key "api_usages", "messages"
  add_foreign_key "chats", "users"
  add_foreign_key "message_sources", "sources"
  add_foreign_key "messages", "chats"
end

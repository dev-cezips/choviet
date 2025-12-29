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

ActiveRecord::Schema[8.0].define(version: 2025_12_27_103000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "analytics_events", force: :cascade do |t|
    t.integer "user_id"
    t.string "event_type", null: false
    t.json "properties", default: {}
    t.json "request_details", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_analytics_events_on_created_at"
    t.index ["event_type", "created_at"], name: "index_analytics_events_on_event_type_and_created_at"
    t.index ["event_type"], name: "index_analytics_events_on_event_type"
    t.index ["user_id"], name: "index_analytics_events_on_user_id"
  end

  create_table "blocks", force: :cascade do |t|
    t.bigint "blocker_id", null: false
    t.bigint "blocked_id", null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blocked_id"], name: "index_blocks_on_blocked_id"
    t.index ["blocker_id", "blocked_id"], name: "index_blocks_on_blocker_id_and_blocked_id", unique: true
    t.index ["blocker_id"], name: "index_blocks_on_blocker_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name_vi"
    t.string "name_ko"
    t.string "icon"
    t.integer "position"
    t.integer "parent_id"
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_categories_on_parent_id"
  end

  create_table "chat_rooms", force: :cascade do |t|
    t.integer "post_id", null: false
    t.integer "buyer_id"
    t.integer "seller_id"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "trade_status", default: 0, null: false
    t.index ["post_id"], name: "index_chat_rooms_on_post_id"
    t.index ["trade_status"], name: "index_chat_rooms_on_trade_status"
  end

  create_table "communities", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.text "description"
    t.string "location_code"
    t.integer "member_count"
    t.boolean "is_private"
    t.json "settings"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "community_memberships", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "community_id", null: false
    t.integer "role"
    t.datetime "joined_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["community_id"], name: "index_community_memberships_on_community_id"
    t.index ["user_id"], name: "index_community_memberships_on_user_id"
  end

  create_table "conversation_messages", force: :cascade do |t|
    t.integer "conversation_id", null: false
    t.integer "user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_conversation_messages_on_conversation_id"
    t.index ["user_id"], name: "index_conversation_messages_on_user_id"
  end

  create_table "conversation_participants", force: :cascade do |t|
    t.integer "conversation_id", null: false
    t.integer "user_id", null: false
    t.datetime "last_read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id", "user_id"], name: "index_conversation_participants_on_conversation_id_and_user_id", unique: true
    t.index ["conversation_id"], name: "index_conversation_participants_on_conversation_id"
    t.index ["user_id"], name: "index_conversation_participants_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.string "kind", default: "direct", null: false
    t.bigint "user_a_id", null: false
    t.bigint "user_b_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["kind", "user_a_id", "user_b_id"], name: "index_conversations_on_kind_and_user_a_id_and_user_b_id", unique: true
  end

  create_table "favorites", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_favorites_on_post_id"
    t.index ["user_id", "post_id"], name: "index_favorites_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "likes", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_likes_on_post_id"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name_ko"
    t.string "name_vi"
    t.string "code", null: false
    t.float "lat"
    t.float "lng"
    t.integer "parent_id"
    t.integer "level", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_locations_on_code", unique: true
    t.index ["parent_id"], name: "index_locations_on_parent_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "chat_room_id", null: false
    t.integer "sender_id"
    t.text "content_raw"
    t.text "content_translated"
    t.string "src_lang"
    t.boolean "is_system"
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "system_message", default: false, null: false
    t.index ["chat_room_id"], name: "index_messages_on_chat_room_id"
    t.index ["system_message"], name: "index_messages_on_system_message"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "recipient_id", null: false
    t.integer "actor_id"
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.integer "kind", default: 0, null: false
    t.string "title"
    t.text "body"
    t.json "data"
    t.integer "status", default: 0, null: false
    t.datetime "delivered_at"
    t.string "failure_reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["recipient_id", "kind", "created_at"], name: "index_notifications_for_listing"
    t.index ["recipient_id", "status"], name: "index_notifications_on_recipient_id_and_status"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
    t.index ["status"], name: "index_notifications_on_status"
  end

  create_table "posts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_type"
    t.string "title"
    t.text "content"
    t.string "location_code"
    t.boolean "target_korean"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "category_id"
    t.integer "community_id"
    t.float "latitude"
    t.float "longitude"
    t.integer "location_id"
    t.integer "views_count", default: 0, null: false
    t.integer "favorites_count", default: 0, null: false
    t.index ["category_id"], name: "index_posts_on_category_id"
    t.index ["community_id"], name: "index_posts_on_community_id"
    t.index ["content"], name: "index_posts_on_content"
    t.index ["latitude", "longitude"], name: "index_posts_on_latitude_and_longitude"
    t.index ["location_code"], name: "index_posts_on_location_code"
    t.index ["location_id"], name: "index_posts_on_location_id"
    t.index ["post_type"], name: "index_posts_on_post_type"
    t.index ["status"], name: "index_posts_on_status"
    t.index ["title"], name: "index_posts_on_title"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.integer "post_id"
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.integer "condition"
    t.text "images"
    t.boolean "sold"
    t.string "currency"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_products_on_post_id"
  end

  create_table "push_endpoints", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "platform", default: 0, null: false
    t.string "token", null: false
    t.string "device_id"
    t.string "endpoint_url"
    t.json "keys"
    t.boolean "active", default: true, null: false
    t.datetime "last_seen_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_push_endpoints_on_active"
    t.index ["user_id", "platform", "token"], name: "index_push_endpoints_unique", unique: true
    t.index ["user_id"], name: "index_push_endpoints_on_user_id"
  end

  create_table "quick_replies", force: :cascade do |t|
    t.string "category"
    t.string "content_vi"
    t.string "content_ko"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reports", force: :cascade do |t|
    t.integer "reporter_id", null: false
    t.string "reportable_type", null: false
    t.integer "reportable_id", null: false
    t.string "reason_code", null: false
    t.text "description"
    t.string "status", default: "pending", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reason"
    t.string "category"
    t.text "admin_note"
    t.bigint "handled_by_id"
    t.datetime "handled_at"
    t.index ["handled_by_id"], name: "index_reports_on_handled_by_id"
    t.index ["reason_code"], name: "index_reports_on_reason_code"
    t.index ["reportable_type", "reportable_id"], name: "index_reports_on_reported"
    t.index ["reporter_id", "reportable_id", "reportable_type"], name: "index_unique_report", unique: true
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
    t.index ["status"], name: "index_reports_on_status"
  end

  create_table "review_reactions", force: :cascade do |t|
    t.integer "review_id", null: false
    t.integer "user_id", null: false
    t.boolean "helpful", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["review_id", "user_id"], name: "index_review_reactions_on_review_id_and_user_id", unique: true
    t.index ["review_id"], name: "index_review_reactions_on_review_id"
    t.index ["user_id"], name: "index_review_reactions_on_user_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "chat_room_id", null: false
    t.integer "reviewer_id", null: false
    t.integer "reviewee_id", null: false
    t.integer "rating", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "visibility", default: true, null: false
    t.index ["chat_room_id", "reviewer_id"], name: "index_reviews_on_chat_room_id_and_reviewer_id", unique: true
    t.index ["chat_room_id"], name: "index_reviews_on_chat_room_id"
    t.index ["reviewee_id"], name: "index_reviews_on_reviewee_id"
    t.index ["reviewer_id"], name: "index_reviews_on_reviewer_id"
  end

  create_table "titles", force: :cascade do |t|
    t.string "name_vi"
    t.string "key"
    t.text "description"
    t.string "category"
    t.integer "level_required"
    t.string "icon"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_titles_on_key", unique: true
    t.index ["level_required"], name: "index_titles_on_level_required"
  end

  create_table "user_titles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "title_id", null: false
    t.datetime "granted_at"
    t.boolean "primary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["title_id"], name: "index_user_titles_on_title_id"
    t.index ["user_id"], name: "index_user_titles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale"
    t.string "location_code"
    t.integer "reputation_score"
    t.string "name"
    t.string "phone"
    t.text "bio"
    t.boolean "verified"
    t.string "avatar_url"
    t.float "latitude"
    t.float "longitude"
    t.integer "location_radius", default: 3
    t.integer "location_id"
    t.boolean "admin", default: false, null: false
    t.integer "exp", default: 0, null: false
    t.integer "level", default: 1, null: false
    t.decimal "rating", precision: 3, scale: 2, default: "0.0"
    t.integer "trades_count", default: 0
    t.boolean "notification_push_enabled", default: true, null: false
    t.boolean "notification_dm_enabled", default: true, null: false
    t.boolean "notification_email_enabled", default: true, null: false
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["exp"], name: "index_users_on_exp"
    t.index ["latitude", "longitude"], name: "index_users_on_latitude_and_longitude"
    t.index ["level"], name: "index_users_on_level"
    t.index ["location_id"], name: "index_users_on_location_id"
    t.index ["notification_push_enabled"], name: "index_users_on_notification_push_enabled"
    t.index ["rating"], name: "index_users_on_rating"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["trades_count"], name: "index_users_on_trades_count"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "analytics_events", "users"
  add_foreign_key "blocks", "users", column: "blocked_id"
  add_foreign_key "blocks", "users", column: "blocker_id"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "chat_rooms", "posts"
  add_foreign_key "community_memberships", "communities"
  add_foreign_key "community_memberships", "users"
  add_foreign_key "conversation_messages", "conversations"
  add_foreign_key "conversation_messages", "users"
  add_foreign_key "conversation_participants", "conversations"
  add_foreign_key "conversation_participants", "users"
  add_foreign_key "conversations", "users", column: "user_a_id"
  add_foreign_key "conversations", "users", column: "user_b_id"
  add_foreign_key "favorites", "posts"
  add_foreign_key "favorites", "users"
  add_foreign_key "likes", "posts"
  add_foreign_key "likes", "users"
  add_foreign_key "locations", "locations", column: "parent_id"
  add_foreign_key "messages", "chat_rooms"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "posts", "categories"
  add_foreign_key "posts", "communities"
  add_foreign_key "posts", "locations"
  add_foreign_key "posts", "users"
  add_foreign_key "products", "posts"
  add_foreign_key "push_endpoints", "users"
  add_foreign_key "reports", "users", column: "handled_by_id"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "review_reactions", "reviews"
  add_foreign_key "review_reactions", "users"
  add_foreign_key "reviews", "chat_rooms"
  add_foreign_key "reviews", "users", column: "reviewee_id"
  add_foreign_key "reviews", "users", column: "reviewer_id"
  add_foreign_key "user_titles", "titles"
  add_foreign_key "user_titles", "users"
  add_foreign_key "users", "locations"
end

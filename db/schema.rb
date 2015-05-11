# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150219220327) do

  create_table "annotations", force: :cascade do |t|
    t.integer  "user_id"
    t.text     "json"
    t.text     "text"
    t.string   "druid",      limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "annotations", ["druid"], name: "index_annotations_on_druid"
  add_index "annotations", ["user_id"], name: "index_annotations_on_user_id"

  create_table "bookmarks", force: :cascade do |t|
    t.integer  "user_id",                   null: false
    t.string   "document_id",   limit: 255
    t.string   "title",         limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "user_type",     limit: 255
    t.string   "document_type", limit: 255
  end

  add_index "bookmarks", ["user_id"], name: "index_bookmarks_on_user_id"

  create_table "change_logs", force: :cascade do |t|
    t.integer  "user_id",                null: false
    t.string   "druid",      limit: 255, null: false
    t.string   "operation",  limit: 255, null: false
    t.text     "note"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "change_logs", ["druid"], name: "index_change_logs_on_druid"
  add_index "change_logs", ["operation"], name: "index_change_logs_on_operation"
  add_index "change_logs", ["user_id"], name: "index_change_logs_on_user_id"

  create_table "flags", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "druid",              limit: 255,                   null: false
    t.string   "flag_type",          limit: 255, default: "error", null: false
    t.text     "comment"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "resolution",         limit: 255
    t.integer  "resolving_user"
    t.datetime "resolved_time"
    t.string   "state",              limit: 255, default: "open"
    t.string   "notification_state", limit: 255
    t.text     "private_comment"
  end

  add_index "flags", ["druid"], name: "index_flags_on_druid"
  add_index "flags", ["flag_type"], name: "index_flags_on_flag_type"
  add_index "flags", ["resolved_time"], name: "index_flags_on_resolved_time"
  add_index "flags", ["resolving_user"], name: "index_flags_on_resolving_user"
  add_index "flags", ["state"], name: "index_flags_on_state"
  add_index "flags", ["user_id"], name: "index_flags_on_user_id"

  create_table "galleries", force: :cascade do |t|
    t.integer  "user_id",                                       null: false
    t.string   "title",             limit: 255
    t.text     "description"
    t.string   "gallery_type",      limit: 255,                 null: false
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
    t.integer  "views",                         default: 0,     null: false
    t.string   "slug",              limit: 255
    t.boolean  "featured",                      default: false, null: false
    t.integer  "position"
    t.string   "visibility",        limit: 255
    t.integer  "saved_items_count",             default: 0,     null: false
  end

  add_index "galleries", ["featured"], name: "index_galleries_on_featured"
  add_index "galleries", ["gallery_type"], name: "index_galleries_on_gallery_type"
  add_index "galleries", ["position"], name: "index_galleries_on_position"
  add_index "galleries", ["slug"], name: "index_galleries_on_slug", unique: true
  add_index "galleries", ["user_id"], name: "index_galleries_on_user_id"

  create_table "items", force: :cascade do |t|
    t.string   "druid",            limit: 255
    t.integer  "visibility_value"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.string   "title",            limit: 400
  end

  add_index "items", ["druid"], name: "index_items_on_druid", unique: true

  create_table "ontologies", force: :cascade do |t|
    t.string   "field",      limit: 255
    t.string   "value",      limit: 255
    t.integer  "position"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "ontologies", ["field"], name: "index_ontologies_on_field"

  create_table "saved_items", force: :cascade do |t|
    t.string   "druid",       limit: 255, null: false
    t.integer  "gallery_id",              null: false
    t.text     "description"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.integer  "position"
  end

  add_index "saved_items", ["druid"], name: "index_saved_items_on_druid"
  add_index "saved_items", ["gallery_id"], name: "index_saved_items_on_gallery_id"
  add_index "saved_items", ["position"], name: "index_saved_items_on_position"

  create_table "searches", force: :cascade do |t|
    t.text     "query_params"
    t.integer  "user_id"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "user_type",    limit: 255
  end

  add_index "searches", ["user_id"], name: "index_searches_on_user_id"

  create_table "users", force: :cascade do |t|
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "sunet",                  limit: 255, default: "",    null: false
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.string   "confirmation_token",     limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",      limit: 255
    t.integer  "failed_attempts",                    default: 0
    t.string   "unlock_token",           limit: 255
    t.datetime "locked_at"
    t.string   "authentication_token",   limit: 255
    t.string   "role",                   limit: 255, default: "",    null: false
    t.text     "bio",                                default: "",    null: false
    t.string   "first_name",             limit: 255, default: "",    null: false
    t.string   "last_name",              limit: 255, default: "",    null: false
    t.boolean  "public",                             default: false, null: false
    t.string   "url",                    limit: 255, default: ""
    t.string   "username",               limit: 255, default: "",    null: false
    t.string   "twitter",                limit: 255
    t.string   "avatar",                 limit: 255
    t.integer  "spam_flags",                         default: 0,     null: false
    t.boolean  "active",                             default: true,  null: false
    t.integer  "login_count",                        default: 0,     null: false
  end

  add_index "users", ["active"], name: "index_users_on_active"
  add_index "users", ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
  add_index "users", ["email"], name: "index_users_on_email"
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  add_index "users", ["sunet"], name: "index_users_on_sunet"
  add_index "users", ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  add_index "users", ["username"], name: "index_users_on_username"

end

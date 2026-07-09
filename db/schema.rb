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

ActiveRecord::Schema[8.0].define(version: 2026_07_09_143000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assets", force: :cascade do |t|
    t.string "name", null: false
    t.string "asset_type", null: false
    t.string "serial_number"
    t.date "purchase_date"
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_type"], name: "index_assets_on_asset_type"
    t.index ["company_id"], name: "index_assets_on_company_id"
    t.index ["serial_number"], name: "index_assets_on_serial_number", unique: true, where: "(serial_number IS NOT NULL)"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "city"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "role", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "role"], name: "index_contacts_on_company_id_and_role"
    t.index ["company_id"], name: "index_contacts_on_company_id"
  end

  create_table "maintenance_records", force: :cascade do |t|
    t.text "description", null: false
    t.datetime "performed_at", null: false
    t.decimal "cost", precision: 10, scale: 2, null: false
    t.bigint "asset_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id", "performed_at"], name: "index_maintenance_records_on_asset_id_and_performed_at"
    t.index ["asset_id"], name: "index_maintenance_records_on_asset_id"
    t.index ["performed_at"], name: "index_maintenance_records_on_performed_at"
  end

  create_table "software_licenses", force: :cascade do |t|
    t.string "software_name", null: false
    t.string "license_key"
    t.date "expiration_date", null: false
    t.bigint "asset_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id", "expiration_date"], name: "index_software_licenses_on_asset_id_and_expiration_date"
    t.index ["asset_id"], name: "index_software_licenses_on_asset_id"
    t.index ["expiration_date"], name: "index_software_licenses_on_expiration_date"
  end

  add_foreign_key "assets", "companies"
  add_foreign_key "contacts", "companies"
  add_foreign_key "maintenance_records", "assets"
  add_foreign_key "software_licenses", "assets"
end

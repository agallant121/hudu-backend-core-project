class CreateMaintenanceRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :maintenance_records do |t|
      t.text :description, null: false
      t.datetime :performed_at, null: false
      t.decimal :cost, precision: 10, scale: 2, null: false
      t.references :asset, null: false, foreign_key: true

      t.timestamps
    end

    add_index :maintenance_records, :performed_at
    add_index :maintenance_records, [ :asset_id, :performed_at ]
  end
end

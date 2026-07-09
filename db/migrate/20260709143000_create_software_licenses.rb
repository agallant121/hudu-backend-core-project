class CreateSoftwareLicenses < ActiveRecord::Migration[8.0]
  def change
    create_table :software_licenses do |t|
      t.string :software_name, null: false
      t.string :license_key
      t.date :expiration_date, null: false
      t.references :asset, null: false, foreign_key: true

      t.timestamps
    end

    add_index :software_licenses, :expiration_date
    add_index :software_licenses, [ :asset_id, :expiration_date ]
  end
end

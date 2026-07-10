class RemoveRedundantReportIndexes < ActiveRecord::Migration[8.0]
  def change
    remove_index :software_licenses, name: "index_software_licenses_on_expiration_date"
    remove_index :maintenance_records, name: "index_maintenance_records_on_performed_at"
  end
end

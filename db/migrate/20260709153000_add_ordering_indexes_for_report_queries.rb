class AddOrderingIndexesForReportQueries < ActiveRecord::Migration[8.0]
  def change
    add_index :software_licenses, [ :expiration_date, :id ]
    add_index :maintenance_records, [ :performed_at, :id ]
  end
end

module Reports
  class MaintenanceCostsQuery
  def self.call(start_date:, end_date:)
    new(start_date:, end_date:).call
  end

  def initialize(start_date:, end_date:)
    @start_date = start_date
    @end_date = end_date
  end

  def call
    {
      date_range: {
        start_date:,
        end_date:
      },
      summary:,
      by_company:,
      by_asset_type:
    }
  end

  private

  attr_reader :start_date, :end_date

  def summary
    {
      total_cost: total_cost,
      total_maintenance_count: total_maintenance_count,
      avg_cost_per_maintenance: average(total_cost, total_maintenance_count)
    }
  end

  def by_company
    @by_company ||= maintenance_records
      .joins(asset: :company)
      .select(
        "companies.id AS company_id",
        "companies.name AS company_name",
        "SUM(maintenance_records.cost) AS total_cost",
        "COUNT(maintenance_records.id) AS maintenance_count",
        "COUNT(DISTINCT maintenance_records.asset_id) AS assets_serviced"
      )
      .group("companies.id", "companies.name")
      .order(Arel.sql("SUM(maintenance_records.cost) DESC"), "companies.id ASC")
      .map do |record|
        total_cost = record.total_cost
        maintenance_count = record.maintenance_count.to_i

        {
          company_id: record.company_id,
          company_name: record.company_name,
          total_cost:,
          maintenance_count:,
          assets_serviced: record.assets_serviced.to_i,
          avg_cost_per_service: average(total_cost, maintenance_count)
        }
      end
  end

  def by_asset_type
    @by_asset_type ||= maintenance_records
      .joins(:asset)
      .select(
        "assets.asset_type AS asset_type",
        "SUM(maintenance_records.cost) AS total_cost",
        "COUNT(maintenance_records.id) AS maintenance_count"
      )
      .group("assets.asset_type")
      .each_with_object({}) do |record, result|
        result[record.asset_type] = {
          total_cost: record.total_cost,
          maintenance_count: record.maintenance_count.to_i
        }
      end
  end

  def total_cost
    @total_cost ||= maintenance_records.sum(:cost)
  end

  def total_maintenance_count
    @total_maintenance_count ||= maintenance_records.count
  end

  def maintenance_records
    @maintenance_records ||= MaintenanceRecord.where(performed_at: date_range)
  end

  def date_range
    start_date.beginning_of_day..end_date.end_of_day
  end

  def average(total, count)
    return 0 if count.zero?

    total / count
  end
  end
end

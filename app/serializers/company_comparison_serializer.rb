class CompanyComparisonSerializer
  def initialize(data)
    @data = data
  end

  def as_json
    {
      companies: companies,
      totals: totals
    }
  end

  private

  attr_reader :data

  def companies
    data[:companies].map do |metrics|
      company = metrics[:company]

      {
        id: company.id,
        name: company.name,
        total_assets: metrics[:total_assets],
        avg_asset_age_years: avg_asset_age_years(metrics),
        maintenance_cost_ytd: metrics[:maintenance_cost_ytd].to_f,
        expiring_licenses_count: metrics[:expiring_licenses_count],
        last_maintenance_date: last_maintenance_date(metrics)
      }
    end
  end

  def totals
    {
      total_assets: data[:totals][:total_assets],
      total_maintenance_cost: data[:totals][:total_maintenance_cost].to_f,
      total_expiring_licenses: data[:totals][:total_expiring_licenses]
    }
  end

  def avg_asset_age_years(metrics)
    metrics[:avg_asset_age_years]&.to_f&.round(2)
  end

  def last_maintenance_date(metrics)
    metrics[:last_maintenance_date]&.iso8601
  end
end

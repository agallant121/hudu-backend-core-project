class CompanyComparisonQuery
  def self.call(company_ids:)
    new(company_ids:).call
  end

  def initialize(company_ids:)
    @company_ids = company_ids
  end

  def call
    {
      companies: company_metrics,
      totals: totals
    }
  end

  private

  attr_reader :company_ids

  def companies
    @companies ||= Company.where(id: company_ids).order(:name).to_a
  end

  def company_metrics
    @company_metrics ||= companies.map do |company|
      {
        company:,
        total_assets: total_assets_by_company[company.id] || 0,
        avg_asset_age_years: avg_asset_age_years_by_company[company.id],
        maintenance_cost_ytd: maintenance_cost_ytd_by_company[company.id] || 0,
        expiring_licenses_count: expiring_licenses_count_by_company[company.id] || 0,
        last_maintenance_date: last_maintenance_date_by_company[company.id]&.to_date
      }
    end
  end

  def totals
    {
      total_assets: company_metrics.sum { |metrics| metrics[:total_assets] },
      total_maintenance_cost: company_metrics.sum { |metrics| metrics[:maintenance_cost_ytd] },
      total_expiring_licenses: company_metrics.sum { |metrics| metrics[:expiring_licenses_count] }
    }
  end

  def total_assets_by_company
    @total_assets_by_company ||= Asset
      .where(company_id: company_ids)
      .group(:company_id)
      .count
  end

  def avg_asset_age_years_by_company
    @avg_asset_age_years_by_company ||= Asset
      .where(company_id: company_ids)
      .where.not(purchase_date: nil)
      .group(:company_id)
      .average(asset_age_years_sql)
  end

  def maintenance_cost_ytd_by_company
    @maintenance_cost_ytd_by_company ||= MaintenanceRecord
      .joins(:asset)
      .where(assets: { company_id: company_ids })
      .where(performed_at: year_to_date_range)
      .group("assets.company_id")
      .sum(:cost)
  end

  def expiring_licenses_count_by_company
    @expiring_licenses_count_by_company ||= SoftwareLicense
      .joins(:asset)
      .where(assets: { company_id: company_ids })
      .where(expiration_date: Date.current..60.days.from_now.to_date)
      .group("assets.company_id")
      .count
  end

  def last_maintenance_date_by_company
    @last_maintenance_date_by_company ||= MaintenanceRecord
      .joins(:asset)
      .where(assets: { company_id: company_ids })
      .group("assets.company_id")
      .maximum(:performed_at)
  end

  def asset_age_years_sql
    as_of_date = ActiveRecord::Base.connection.quote(Date.current)

    Arel.sql("(#{as_of_date}::date - purchase_date)::decimal / 365.0")
  end

  def year_to_date_range
    Time.current.beginning_of_year..Time.current
  end
end

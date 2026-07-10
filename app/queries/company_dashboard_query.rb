class CompanyDashboardQuery
  def self.call(company:)
    new(company:).call
  end

  def initialize(company:)
    @company = company
  end

  def call
    {
      company:,
      total_assets:,
      assets_by_type:,
      total_maintenance_cost_ytd:,
      expiring_licenses:,
      recent_maintenance:,
      primary_contact: company.primary_contact
    }
  end

  private

  attr_reader :company

  def total_assets
    company.assets.count
  end

  def assets_by_type
    company.assets.group(:asset_type).order(:asset_type).count
  end

  def total_maintenance_cost_ytd
    company_maintenance_records
      .where(performed_at: year_to_date_range)
      .sum(:cost)
  end

  def expiring_licenses
    SoftwareLicense
      .joins(:asset)
      .includes(:asset)
      .where(assets: { company_id: company.id })
      .where(expiration_date: Date.current..60.days.from_now.to_date)
      .order(:expiration_date, :id)
      .limit(10)
      .to_a
  end

  def recent_maintenance
    company_maintenance_records
      .includes(:asset)
      .order(performed_at: :desc, id: :desc)
      .limit(5)
      .to_a
  end

  def company_maintenance_records
    MaintenanceRecord
      .joins(:asset)
      .where(assets: { company_id: company.id })
  end

  def year_to_date_range
    Time.current.beginning_of_year..Time.current
  end
end

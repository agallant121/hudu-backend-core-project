class CompanyDashboardSerializer
  def initialize(data)
    @data = data
  end

  def as_json
    {
      company: {
        id: company.id,
        name: company.name,
        total_assets: total_assets,
        assets_by_type: assets_by_type,
        total_maintenance_cost_ytd: total_maintenance_cost_ytd,
        expiring_licenses: expiring_licenses,
        recent_maintenance: recent_maintenance,
        primary_contact: primary_contact
      }
    }
  end

  private

  attr_reader :data

  def company
    data[:company]
  end

  def total_assets
    data[:total_assets]
  end

  def assets_by_type
    data[:assets_by_type]
  end

  def total_maintenance_cost_ytd
    data[:total_maintenance_cost_ytd].to_f
  end

  def expiring_licenses
    data[:expiring_licenses].map do |license|
      {
        software_name: license.software_name,
        expiration_date: license.expiration_date.iso8601,
        asset_name: license.asset.name,
        days_until_expiration: license.days_until_expiration
      }
    end
  end

  def recent_maintenance
    data[:recent_maintenance].map do |maintenance_record|
      {
        asset_name: maintenance_record.asset.name,
        description: maintenance_record.description,
        performed_at: maintenance_record.performed_at.iso8601,
        cost: maintenance_record.cost.to_f
      }
    end
  end

  def primary_contact
    contact = data[:primary_contact]
    return nil unless contact

    {
      name: contact.name,
      email: contact.email,
      role: contact.role
    }
  end
end

class ExpiringLicensesSerializer
  def initialize(data)
    @data = data
  end

  def as_json
    {
      expiring_licenses: expiring_licenses,
      summary: summary
    }
  end

  private

  attr_reader :data

  def expiring_licenses
    data[:expiring_licenses].map do |license|
      {
        id: license.id,
        software_name: license.software_name,
        license_key: license.license_key,
        expiration_date: license.expiration_date.iso8601,
        days_until_expiration: license.days_until_expiration,
        asset: asset(license.asset),
        company_contact: company_contact(license.asset.company)
      }
    end
  end

  def asset(asset)
    {
      id: asset.id,
      name: asset.name,
      asset_type: asset.asset_type,
      company_name: asset.company.name
    }
  end

  def company_contact(company)
    company.primary_contact&.email
  end

  def summary
    {
      total_expiring: data[:summary][:total_expiring],
      by_software: data[:summary][:by_software]
    }
  end
end

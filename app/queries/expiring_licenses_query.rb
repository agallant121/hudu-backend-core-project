class ExpiringLicensesQuery
  def self.call(days:)
    new(days:).call
  end

  def initialize(days:)
    @days = days
  end

  def call
    {
      expiring_licenses:,
      summary:
    }
  end

  private

  attr_reader :days

  def expiring_licenses
    @expiring_licenses ||= matching_licenses
      .includes(asset: { company: :contacts })
      .order(:expiration_date, :id)
      .to_a
  end

  def summary
    {
      total_expiring: expiring_licenses.size,
      by_software:
    }
  end

  def by_software
    @by_software ||= matching_licenses.group(:software_name).count
  end

  # Hudu clarified this should include already expired licenses,
  # so we intentionally query everything on or before the cutoff.
  def matching_licenses
    @matching_licenses ||= SoftwareLicense.where("expiration_date <= ?", cutoff_date)
  end

  def cutoff_date
    @cutoff_date ||= Date.current + days.days
  end
end

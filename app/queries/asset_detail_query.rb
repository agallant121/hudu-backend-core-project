class AssetDetailQuery
  def self.call(asset:)
    new(asset:).call
  end

  def initialize(asset:)
    @asset = asset
  end

  def call
    {
      asset:,
      company:,
      company_contact: company.primary_contact,
      maintenance_count:,
      total_maintenance_cost:,
      last_maintenance_date:,
      software_licenses:,
      recent_notes:
    }
  end

  private

  attr_reader :asset

  def company
    @company ||= asset.company
  end

  def maintenance_records
    @maintenance_records ||= asset.maintenance_records
  end

  def maintenance_count
    maintenance_records.count
  end

  def total_maintenance_cost
    maintenance_records.sum(:cost)
  end

  def last_maintenance_date
    maintenance_records.maximum(:performed_at)&.to_date
  end

  def software_licenses
    @software_licenses ||= asset.software_licenses.order(:id).to_a
  end

  def recent_notes
    @recent_notes ||= asset
      .notes
      .includes(:author)
      .order(created_at: :desc, id: :desc)
      .limit(10)
      .to_a
  end
end

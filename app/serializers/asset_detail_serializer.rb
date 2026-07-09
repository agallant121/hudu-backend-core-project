class AssetDetailSerializer
  def initialize(data)
    @data = data
  end

  def as_json
    {
      asset: {
        id: asset.id,
        name: asset.name,
        asset_type: asset.asset_type,
        serial_number: asset.serial_number,
        purchase_date: purchase_date,
        company_name: company.name,
        company_contact_email: company_contact_email,
        maintenance_count: data[:maintenance_count],
        total_maintenance_cost: data[:total_maintenance_cost].to_f,
        last_maintenance_date: last_maintenance_date,
        software_licenses: software_licenses,
        recent_notes: recent_notes
      }
    }
  end

  private

  attr_reader :data

  def asset
    data[:asset]
  end

  def company
    data[:company]
  end

  def purchase_date
    asset.purchase_date&.iso8601
  end

  def company_contact_email
    data[:company_contact]&.email
  end

  def last_maintenance_date
    data[:last_maintenance_date]&.iso8601
  end

  def software_licenses
    data[:software_licenses].map do |license|
      {
        id: license.id,
        software_name: license.software_name,
        expiration_date: license.expiration_date.iso8601,
        days_until_expiration: license.days_until_expiration,
        expired: license.expired?
      }
    end
  end

  def recent_notes
    data[:recent_notes].map do |note|
      {
        id: note.id,
        content: note.content,
        author_name: note.author.name,
        created_at: note.created_at.iso8601
      }
    end
  end
end

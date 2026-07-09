class MaintenanceCostsSerializer
  def initialize(data)
    @data = data
  end

  def as_json
    {
      date_range: date_range,
      summary: summary,
      by_company: by_company,
      by_asset_type: by_asset_type
    }
  end

  private

  attr_reader :data

  def date_range
    {
      start_date: data[:date_range][:start_date].iso8601,
      end_date: data[:date_range][:end_date].iso8601
    }
  end

  def summary
    {
      total_cost: money(data[:summary][:total_cost]),
      total_maintenance_count: data[:summary][:total_maintenance_count],
      avg_cost_per_maintenance: average(data[:summary][:avg_cost_per_maintenance])
    }
  end

  def by_company
    data[:by_company].map do |company|
      {
        company_id: company[:company_id],
        company_name: company[:company_name],
        total_cost: money(company[:total_cost]),
        maintenance_count: company[:maintenance_count],
        assets_serviced: company[:assets_serviced],
        avg_cost_per_service: average(company[:avg_cost_per_service])
      }
    end
  end

  def by_asset_type
    data[:by_asset_type].transform_values do |metrics|
      {
        total_cost: money(metrics[:total_cost]),
        maintenance_count: metrics[:maintenance_count]
      }
    end
  end

  def money(value)
    value.to_f
  end

  def average(value)
    value.to_f.round(2)
  end
end

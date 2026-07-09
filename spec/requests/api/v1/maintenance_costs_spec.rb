require "rails_helper"

RSpec.describe "Maintenance Costs", type: :request do
  describe "GET /api/v1/reports/maintenance_costs" do
    it "returns maintenance cost data for a valid date range" do
      start_date = Date.new(2026, 7, 1)
      end_date = Date.new(2026, 7, 31)
      acme = create(:company, name: "Acme Corp")
      beta = create(:company, name: "Beta Corp")
      outside_company = create(:company, name: "Outside Corp")
      acme_server = create(:asset, company: acme, asset_type: "server")
      acme_workstation = create(:asset, company: acme, asset_type: "workstation")
      beta_server = create(:asset, company: beta, asset_type: "server")
      outside_printer = create(:asset, company: outside_company, asset_type: "printer")

      create(:maintenance_record, asset: acme_server, cost: 100.25, performed_at: start_date.beginning_of_day)
      create(:maintenance_record, asset: acme_server, cost: 200.50, performed_at: Time.zone.local(2026, 7, 15, 12, 0, 0))
      create(:maintenance_record, asset: acme_workstation, cost: 300.75, performed_at: end_date.end_of_day)
      create(:maintenance_record, asset: beta_server, cost: 50.00, performed_at: Time.zone.local(2026, 7, 20, 9, 0, 0))
      create(:maintenance_record, asset: outside_printer, cost: 999.99, performed_at: start_date.beginning_of_day - 1.second)
      create(:maintenance_record, asset: outside_printer, cost: 888.88, performed_at: end_date.end_of_day + 1.second)

      get "/api/v1/reports/maintenance_costs", params: { start_date: start_date.iso8601, end_date: end_date.iso8601 }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.keys).to contain_exactly("date_range", "summary", "by_company", "by_asset_type")

      expect(json.fetch("date_range")).to eq(
        {
          "start_date" => "2026-07-01",
          "end_date" => "2026-07-31"
        }
      )

      summary = json.fetch("summary")
      expect(summary.keys).to contain_exactly("total_cost", "total_maintenance_count", "avg_cost_per_maintenance")
      expect(summary).to eq(
        {
          "total_cost" => 651.5,
          "total_maintenance_count" => 4,
          "avg_cost_per_maintenance" => 162.88
        }
      )

      by_company = json.fetch("by_company")
      expect(by_company.map(&:keys)).to all(
        contain_exactly(
          "company_id",
          "company_name",
          "total_cost",
          "maintenance_count",
          "assets_serviced",
          "avg_cost_per_service"
        )
      )
      expect(by_company).to eq(
        [
          {
            "company_id" => acme.id,
            "company_name" => "Acme Corp",
            "total_cost" => 601.5,
            "maintenance_count" => 3,
            "assets_serviced" => 2,
            "avg_cost_per_service" => 200.5
          },
          {
            "company_id" => beta.id,
            "company_name" => "Beta Corp",
            "total_cost" => 50.0,
            "maintenance_count" => 1,
            "assets_serviced" => 1,
            "avg_cost_per_service" => 50.0
          }
        ]
      )
      expect(by_company.map { |company| company["company_id"] }).not_to include(outside_company.id)

      by_asset_type = json.fetch("by_asset_type")
      expect(by_asset_type.keys).to contain_exactly("server", "workstation")
      expect(by_asset_type.values.map(&:keys)).to all(contain_exactly("total_cost", "maintenance_count"))
      expect(by_asset_type).to eq(
        {
          "server" => {
            "total_cost" => 350.75,
            "maintenance_count" => 3
          },
          "workstation" => {
            "total_cost" => 300.75,
            "maintenance_count" => 1
          }
        }
      )
    end

    it "returns 400 when start_date is missing" do
      get "/api/v1/reports/maintenance_costs", params: { end_date: "2026-07-31" }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ "error" => "start_date and end_date must be valid dates in YYYY-MM-DD format" })
    end

    it "returns 400 when end_date is missing" do
      get "/api/v1/reports/maintenance_costs", params: { start_date: "2026-07-01" }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ "error" => "start_date and end_date must be valid dates in YYYY-MM-DD format" })
    end

    it "returns 400 when either date is invalid" do
      get "/api/v1/reports/maintenance_costs", params: { start_date: "2026-07-01", end_date: "2026-99-99" }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ "error" => "start_date and end_date must be valid dates in YYYY-MM-DD format" })
    end

    it "returns 400 when start_date is after end_date" do
      get "/api/v1/reports/maintenance_costs", params: { start_date: "2026-08-01", end_date: "2026-07-31" }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ "error" => "start_date must be on or before end_date" })
    end
  end
end

require "rails_helper"

RSpec.describe "Company Comparison", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to Time.zone.local(2026, 7, 9, 12, 0, 0) do
      example.run
    end
  end

  describe "GET /api/v1/reports/company_comparison" do
    it "returns comparison data for valid company IDs" do
      beta = create(:company, name: "Beta Corp")
      acme = create(:company, name: "Acme Corp")
      missing_company_id = Company.maximum(:id) + 100

      acme_server = create(:asset, company: acme, purchase_date: Date.current - 1.year)
      acme_workstation = create(:asset, company: acme, purchase_date: Date.current - 2.years)
      create(:asset, company: acme, purchase_date: nil)

      beta_server = create(:asset, company: beta, purchase_date: Date.current - 1.year)
      create(:asset, company: beta, purchase_date: nil)

      create(:maintenance_record, asset: acme_server, cost: 100.25, performed_at: Time.zone.local(2026, 7, 7, 9, 0, 0))
      create(:maintenance_record, asset: acme_workstation, cost: 999.99, performed_at: Time.zone.local(2025, 12, 31, 9, 0, 0))

      create(:software_license, asset: acme_server, expiration_date: Date.current)
      create(:software_license, asset: acme_workstation, expiration_date: Date.current + 60.days)
      create(:software_license, asset: acme_server, expiration_date: Date.current + 61.days)
      create(:software_license, asset: beta_server, expiration_date: Date.current + 30.days)
      create(:software_license, asset: beta_server, expiration_date: Date.current + 90.days)

      get "/api/v1/reports/company_comparison", params: { company_ids: [ beta.id, missing_company_id, acme.id ] }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.keys).to contain_exactly("companies", "totals")
      expect(json["companies"].map(&:keys)).to all(
        contain_exactly(
          "id",
          "name",
          "total_assets",
          "avg_asset_age_years",
          "maintenance_cost_ytd",
          "expiring_licenses_count",
          "last_maintenance_date"
        )
      )
      expect(json["totals"].keys).to contain_exactly(
        "total_assets",
        "total_maintenance_cost",
        "total_expiring_licenses"
      )

      companies = json.fetch("companies")
      expect(companies.map { |company| company["name"] }).to eq([ "Acme Corp", "Beta Corp" ])
      expect(companies.map { |company| company["id"] }).not_to include(missing_company_id)

      acme_json = companies.first
      expect(acme_json).to include(
        "id" => acme.id,
        "name" => "Acme Corp",
        "total_assets" => 3,
        "avg_asset_age_years" => 1.5,
        "maintenance_cost_ytd" => 100.25,
        "expiring_licenses_count" => 2,
        "last_maintenance_date" => "2026-07-07"
      )

      beta_json = companies.second
      expect(beta_json).to include(
        "id" => beta.id,
        "name" => "Beta Corp",
        "total_assets" => 2,
        "avg_asset_age_years" => 1.0,
        "maintenance_cost_ytd" => 0.0,
        "expiring_licenses_count" => 1,
        "last_maintenance_date" => nil
      )

      expect(json["totals"]).to eq(
        {
          "total_assets" => 5,
          "total_maintenance_cost" => 100.25,
          "total_expiring_licenses" => 3
        }
      )
    end

    it "returns empty companies and zero totals when all company IDs are missing" do
      max_id = Company.maximum(:id).to_i
      missing_ids = [ max_id + 100, max_id + 101 ]

      get "/api/v1/reports/company_comparison", params: { company_ids: missing_ids }

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json["companies"]).to eq([])
      expect(json["totals"]).to eq(
        {
          "total_assets" => 0,
          "total_maintenance_cost" => 0.0,
          "total_expiring_licenses" => 0
        }
      )
    end

    it "returns 400 when company_ids are missing" do
      get "/api/v1/reports/company_comparison"

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ "error" => "company_ids are required" })
    end

    it "returns 400 when more than 50 company IDs are supplied" do
      get "/api/v1/reports/company_comparison", params: { company_ids: (1..51).to_a }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ "error" => "company_ids must include between 1 and 50 IDs" })
    end

    it "returns 400 when company_ids include non-integer values" do
      get "/api/v1/reports/company_comparison", params: { company_ids: [ "abc" ] }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ "error" => "company_ids must be integers" })
    end
  end
end

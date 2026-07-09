require "rails_helper"

RSpec.describe "Expiring Licenses", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to Time.zone.local(2026, 7, 9, 12, 0, 0) do
      example.run
    end
  end

  describe "GET /api/v1/reports/expiring_licenses" do
    it "returns licenses expiring on or before the default cutoff" do
      company = create(:company, name: "Acme Corp")
      create(:contact, company:, name: "Fallback Contact", email: "fallback@acme.com", role: "technical")
      primary_contact = create(:contact, company:, name: "Primary Contact", email: "primary@acme.com", role: Contact::PRIMARY_ROLE)
      server = create(:asset, company:, name: "SERVER-01", asset_type: "server")
      workstation = create(:asset, company:, name: "WORKSTATION-01", asset_type: "workstation")

      expired_license = create(:software_license, asset: server, software_name: "Expired App", license_key: "EXPIRED-KEY", expiration_date: Date.current - 5.days)
      today_license = create(:software_license, asset: server, software_name: "Today App", license_key: "TODAY-KEY", expiration_date: Date.current)
      before_cutoff_license = create(:software_license, asset: workstation, software_name: "Shared App", license_key: "BEFORE-KEY", expiration_date: Date.current + 10.days)
      cutoff_license = create(:software_license, asset: server, software_name: "Shared App", license_key: "CUTOFF-KEY", expiration_date: Date.current + 30.days)
      excluded_license = create(:software_license, asset: server, software_name: "Excluded App", expiration_date: Date.current + 31.days)

      get "/api/v1/reports/expiring_licenses"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.keys).to contain_exactly("expiring_licenses", "summary")

      expiring_licenses = json.fetch("expiring_licenses")
      expect(expiring_licenses.map(&:keys)).to all(
        contain_exactly(
          "id",
          "software_name",
          "license_key",
          "expiration_date",
          "days_until_expiration",
          "asset",
          "company_contact"
        )
      )
      expect(expiring_licenses.map { |license| license.fetch("asset").keys }).to all(
        contain_exactly("id", "name", "asset_type", "company_name")
      )
      expect(expiring_licenses.map { |license| license["id"] }).to eq(
        [
          expired_license.id,
          today_license.id,
          before_cutoff_license.id,
          cutoff_license.id
        ]
      )
      expect(expiring_licenses.map { |license| license["id"] }).not_to include(excluded_license.id)

      expect(expiring_licenses.first).to eq(
        {
          "id" => expired_license.id,
          "software_name" => "Expired App",
          "license_key" => "EXPIRED-KEY",
          "expiration_date" => (Date.current - 5.days).iso8601,
          "days_until_expiration" => -5,
          "asset" => {
            "id" => server.id,
            "name" => "SERVER-01",
            "asset_type" => "server",
            "company_name" => "Acme Corp"
          },
          "company_contact" => primary_contact.email
        }
      )
      expect(expiring_licenses.second).to include(
        "id" => today_license.id,
        "expiration_date" => Date.current.iso8601,
        "days_until_expiration" => 0
      )
      expect(expiring_licenses.fourth).to include(
        "id" => cutoff_license.id,
        "expiration_date" => (Date.current + 30.days).iso8601,
        "days_until_expiration" => 30
      )

      summary = json.fetch("summary")
      expect(summary.keys).to contain_exactly("total_expiring", "by_software")
      expect(summary).to eq(
        {
          "total_expiring" => 4,
          "by_software" => {
            "Expired App" => 1,
            "Today App" => 1,
            "Shared App" => 2
          }
        }
      )
    end

    it "uses a custom days cutoff" do
      asset = create(:asset)
      included_license = create(:software_license, asset:, software_name: "Included App", expiration_date: Date.current + 10.days)
      cutoff_license = create(:software_license, asset:, software_name: "Cutoff App", expiration_date: Date.current + 15.days)
      excluded_license = create(:software_license, asset:, software_name: "Excluded App", expiration_date: Date.current + 16.days)

      get "/api/v1/reports/expiring_licenses", params: { days: 15 }

      expect(response).to have_http_status(:ok)

      expiring_licenses = JSON.parse(response.body).fetch("expiring_licenses")
      expect(expiring_licenses.map { |license| license["id"] }).to eq([ included_license.id, cutoff_license.id ])
      expect(expiring_licenses.map { |license| license["id"] }).not_to include(excluded_license.id)
    end

    it "orders licenses by expiration date and id" do
      asset = create(:asset)
      later_license = create(:software_license, asset:, software_name: "Later App", expiration_date: Date.current + 2.days)
      first_same_day_license = create(:software_license, asset:, software_name: "First Same Day App", expiration_date: Date.current + 1.day)
      second_same_day_license = create(:software_license, asset:, software_name: "Second Same Day App", expiration_date: Date.current + 1.day)

      get "/api/v1/reports/expiring_licenses", params: { days: 2 }

      expect(response).to have_http_status(:ok)

      expiring_licenses = JSON.parse(response.body).fetch("expiring_licenses")
      expect(expiring_licenses.map { |license| license["id"] }).to eq(
        [
          first_same_day_license.id,
          second_same_day_license.id,
          later_license.id
        ]
      )
    end

    it "returns 400 when days is not an integer" do
      get "/api/v1/reports/expiring_licenses", params: { days: "abc" }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ "error" => "days must be a non-negative integer" })
    end

    it "returns 400 when days is negative" do
      get "/api/v1/reports/expiring_licenses", params: { days: "-1" }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ "error" => "days must be a non-negative integer" })
    end
  end
end

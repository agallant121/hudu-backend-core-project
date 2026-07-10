require "rails_helper"

RSpec.describe "Company Dashboard", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to Time.zone.local(2026, 1, 15, 12, 0, 0) do
      example.run
    end
  end

  describe "GET /api/v1/companies/:id/dashboard" do
    it "returns dashboard data for an existing company" do
      company = create(:company, name: "Acme Corp")
      other_company = create(:company)
      workstation = create(:asset, company:, name: "WORKSTATION-01", asset_type: "workstation")
      server = create(:asset, company:, name: "SERVER-01", asset_type: "server")
      create(:asset, company: other_company, asset_type: "printer")
      create(:contact, company:, name: "Fallback Contact", email: "fallback@acme.com", role: "technical")
      create(:contact, company:, name: "John Smith", email: "john@acme.com", role: Contact::PRIMARY_ROLE)

      create(:maintenance_record, asset: server, description: "Current year server work", cost: 100.25, performed_at: Time.zone.local(2026, 1, 10, 10, 0, 0))
      create(:maintenance_record, asset: workstation, description: "Current year workstation work", cost: 200.50, performed_at: Time.zone.local(2026, 1, 11, 10, 0, 0))
      create(:maintenance_record, asset: server, description: "Previous year work", cost: 999.99, performed_at: Time.zone.local(2025, 12, 31, 10, 0, 0))
      create(:maintenance_record, asset: create(:asset, company: other_company), cost: 500.00, performed_at: Time.zone.local(2026, 1, 12, 10, 0, 0))

      6.times do |index|
        create(
          :maintenance_record,
          asset: server,
          description: "Recent maintenance #{index}",
          cost: 10.00 + index,
          performed_at: Time.zone.local(2026, 1, index + 1, 9, 0, 0)
        )
      end

      create(:software_license, asset: server, software_name: "License 30", expiration_date: Date.current + 30.days)
      create(:software_license, asset: workstation, software_name: "License 1", expiration_date: Date.current + 1.day)
      create(:software_license, asset: server, software_name: "License Today", expiration_date: Date.current)
      create(:software_license, asset: server, software_name: "License 61", expiration_date: Date.current + 61.days)
      create(:software_license, asset: create(:asset, company: other_company), software_name: "Other Company License", expiration_date: Date.current + 2.days)

      11.times do |index|
        create(
          :software_license,
          asset: server,
          software_name: "Window License #{index}",
          expiration_date: Date.current + (index + 2).days
        )
      end

      get "/api/v1/companies/#{company.id}/dashboard"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.keys).to eq([ "company" ])

      dashboard = json.fetch("company")
      expect(dashboard.keys).to contain_exactly(
        "id",
        "name",
        "total_assets",
        "assets_by_type",
        "total_maintenance_cost_ytd",
        "expiring_licenses",
        "recent_maintenance",
        "primary_contact"
      )
      expect(dashboard["id"]).to eq(company.id)
      expect(dashboard["name"]).to eq("Acme Corp")
      expect(dashboard["total_assets"]).to eq(2)
      expect(dashboard["assets_by_type"]).to eq({ "server" => 1, "workstation" => 1 })
      expect(dashboard["assets_by_type"].keys).to eq([ "server", "workstation" ])
      expect(dashboard["total_maintenance_cost_ytd"]).to eq(375.75)

      expiring_licenses = dashboard.fetch("expiring_licenses")
      expect(expiring_licenses.size).to eq(10)
      expect(expiring_licenses.map(&:keys)).to all(contain_exactly("software_name", "expiration_date", "asset_name", "days_until_expiration"))
      expect(expiring_licenses.map { |license| license["software_name"] }).to eq(
        [
          "License Today",
          "License 1",
          "Window License 0",
          "Window License 1",
          "Window License 2",
          "Window License 3",
          "Window License 4",
          "Window License 5",
          "Window License 6",
          "Window License 7"
        ]
      )
      expect(expiring_licenses.first).to include(
        "expiration_date" => Date.current.iso8601,
        "asset_name" => "SERVER-01",
        "days_until_expiration" => 0
      )
      expect(expiring_licenses.map { |license| license["software_name"] }).not_to include("License 61", "Other Company License", "License 30")

      recent_maintenance = dashboard.fetch("recent_maintenance")
      expect(recent_maintenance.size).to eq(5)
      expect(recent_maintenance.map(&:keys)).to all(contain_exactly("asset_name", "description", "performed_at", "cost"))
      expect(recent_maintenance.map { |record| record["description"] }).to eq(
        [
          "Current year workstation work",
          "Current year server work",
          "Recent maintenance 5",
          "Recent maintenance 4",
          "Recent maintenance 3"
        ]
      )
      expect(recent_maintenance.first).to include(
        "asset_name" => "WORKSTATION-01",
        "performed_at" => Time.zone.local(2026, 1, 11, 10, 0, 0).iso8601,
        "cost" => 200.5
      )

      expect(dashboard["primary_contact"].keys).to contain_exactly("name", "email", "role")
      expect(dashboard["primary_contact"]).to eq(
        {
          "name" => "John Smith",
          "email" => "john@acme.com",
          "role" => "primary"
        }
      )
    end

    it "uses the first contact when no primary contact exists" do
      company = create(:company)
      create(:contact, company:, name: "Technical Contact", email: "tech@example.com", role: "technical")
      create(:contact, company:, name: "Billing Contact", email: "billing@example.com", role: "billing")

      get "/api/v1/companies/#{company.id}/dashboard"

      expect(response).to have_http_status(:ok)

      dashboard = JSON.parse(response.body).fetch("company")
      expect(dashboard["primary_contact"]).to eq(
        {
          "name" => "Technical Contact",
          "email" => "tech@example.com",
          "role" => "technical"
        }
      )
    end

    it "returns nil for primary contact when the company has no contacts" do
      company = create(:company)

      get "/api/v1/companies/#{company.id}/dashboard"

      expect(response).to have_http_status(:ok)

      dashboard = JSON.parse(response.body).fetch("company")
      expect(dashboard["id"]).to eq(company.id)
      expect(dashboard["primary_contact"]).to be_nil
    end

    it "returns 404 when the company does not exist" do
      get "/api/v1/companies/999999/dashboard"

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq({ "error" => "Company not found" })
    end
  end
end

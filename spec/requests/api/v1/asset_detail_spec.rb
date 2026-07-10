require "rails_helper"

RSpec.describe "Asset Detail", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  around do |example|
    travel_to Time.zone.local(2026, 7, 9, 12, 0, 0) do
      example.run
    end
  end

  describe "GET /api/v1/assets/:id" do
    it "returns asset detail data for an existing asset" do
      company = create(:company, name: "Acme Corp")
      asset = create(
        :asset,
        company:,
        name: "SERVER-01",
        asset_type: "server",
        serial_number: "SN123",
        purchase_date: Date.current - 1.year
      )
      create(:contact, company:, name: "Fallback Contact", email: "fallback@acme.com", role: "technical")
      primary_contact = create(:contact, company:, name: "Primary Contact", email: "primary@acme.com", role: Contact::PRIMARY_ROLE)

      create(:maintenance_record, asset:, cost: 100.25, performed_at: Time.zone.local(2026, 7, 7, 10, 0, 0))
      create(:maintenance_record, asset:, cost: 200.50, performed_at: Time.zone.local(2026, 7, 8, 10, 0, 0))

      expired_license = create(:software_license, asset:, software_name: "Expired App", expiration_date: Date.current - 5.days)
      active_license = create(:software_license, asset:, software_name: "Active App", expiration_date: Date.current + 30.days)

      old_note = create(:note, asset:, content: "Old note", created_at: Time.zone.local(2026, 6, 1, 9, 0, 0))
      notes = 11.times.map do |index|
        create(
          :note,
          asset:,
          content: "Recent note #{index}",
          created_at: Time.zone.local(2026, 7, index + 1, 9, 0, 0)
        )
      end

      get "/api/v1/assets/#{asset.id}"

      expect(response).to have_http_status(:ok)

      json = JSON.parse(response.body)
      expect(json.keys).to eq([ "asset" ])

      asset_json = json.fetch("asset")
      expect(asset_json.keys).to contain_exactly(
        "id",
        "name",
        "asset_type",
        "serial_number",
        "purchase_date",
        "company_name",
        "company_contact_email",
        "maintenance_count",
        "total_maintenance_cost",
        "last_maintenance_date",
        "software_licenses",
        "recent_notes"
      )
      expect(asset_json).to include(
        "id" => asset.id,
        "name" => "SERVER-01",
        "asset_type" => "server",
        "serial_number" => "SN123",
        "purchase_date" => (Date.current - 1.year).iso8601,
        "company_name" => "Acme Corp",
        "company_contact_email" => primary_contact.email,
        "maintenance_count" => 2,
        "total_maintenance_cost" => 300.75,
        "last_maintenance_date" => "2026-07-08"
      )

      software_licenses = asset_json.fetch("software_licenses")
      expect(software_licenses.map(&:keys)).to all(
        contain_exactly(
          "id",
          "software_name",
          "expiration_date",
          "days_until_expiration",
          "expired"
        )
      )
      expect(software_licenses).to eq(
        [
          {
            "id" => expired_license.id,
            "software_name" => "Expired App",
            "expiration_date" => (Date.current - 5.days).iso8601,
            "days_until_expiration" => -5,
            "expired" => true
          },
          {
            "id" => active_license.id,
            "software_name" => "Active App",
            "expiration_date" => (Date.current + 30.days).iso8601,
            "days_until_expiration" => 30,
            "expired" => false
          }
        ]
      )

      recent_notes = asset_json.fetch("recent_notes")
      expected_notes = notes.last(10).reverse
      expect(recent_notes.size).to eq(10)
      expect(recent_notes.map(&:keys)).to all(contain_exactly("id", "content", "author_name", "created_at"))
      expect(recent_notes.map { |note| note["id"] }).to eq(expected_notes.map(&:id))
      expect(recent_notes.map { |note| note["content"] }).to eq(expected_notes.map(&:content))
      expect(recent_notes.first).to include(
        "author_name" => expected_notes.first.author.name,
        "created_at" => expected_notes.first.created_at.iso8601
      )
      expect(recent_notes.map { |note| note["id"] }).not_to include(old_note.id)
    end

    it "uses the first contact when no primary contact exists" do
      company = create(:company)
      asset = create(:asset, company:)
      first_contact = create(:contact, company:, name: "Technical Contact", email: "tech@example.com", role: "technical")
      create(:contact, company:, name: "Billing Contact", email: "billing@example.com", role: "billing")

      get "/api/v1/assets/#{asset.id}"

      expect(response).to have_http_status(:ok)

      asset_json = JSON.parse(response.body).fetch("asset")
      expect(asset_json["company_contact_email"]).to eq(first_contact.email)
    end

    it "returns nil for company contact email when the company has no contacts" do
      company = create(:company)
      asset = create(:asset, company:)

      get "/api/v1/assets/#{asset.id}"

      expect(response).to have_http_status(:ok)

      asset_json = JSON.parse(response.body).fetch("asset")
      expect(asset_json["company_contact_email"]).to be_nil
    end

    it "returns nil for last maintenance date when there are no maintenance records" do
      asset = create(:asset)

      get "/api/v1/assets/#{asset.id}"

      expect(response).to have_http_status(:ok)

      asset_json = JSON.parse(response.body).fetch("asset")
      expect(asset_json["maintenance_count"]).to eq(0)
      expect(asset_json["total_maintenance_cost"]).to eq(0.0)
      expect(asset_json["last_maintenance_date"]).to be_nil
    end

    it "returns 404 when the asset does not exist" do
      get "/api/v1/assets/999999"

      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq({ "error" => "Asset not found" })
    end
  end
end

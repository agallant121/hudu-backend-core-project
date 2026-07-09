require "rails_helper"

RSpec.describe Company, type: :model do
  describe "validations" do
    it "requires a name" do
      company = build(:company, name: nil)

      expect(company).not_to be_valid
      expect(company.errors[:name]).to include("can't be blank")
    end

    it "requires a unique name" do
      create(:company, name: "Acme Corp")
      company = build(:company, name: "Acme Corp")

      expect(company).not_to be_valid
      expect(company.errors[:name]).to include("has already been taken")
    end
  end

  describe "associations" do
    it "has many assets" do
      company = create(:company)
      asset = create(:asset, company:)

      expect(company.assets).to contain_exactly(asset)
    end

    it "has many contacts" do
      company = create(:company)
      contact = create(:contact, company:)

      expect(company.contacts).to contain_exactly(contact)
    end
  end

  describe "#primary_contact" do
    it "returns the primary contact when present" do
      company = create(:company)
      create(:contact, company:, role: "technical")
      primary_contact = create(:contact, company:, role: Contact::PRIMARY_ROLE)

      expect(company.primary_contact).to eq(primary_contact)
    end

    it "falls back to the first contact when no primary contact exists" do
      company = create(:company)
      first_contact = create(:contact, company:, role: "technical")
      create(:contact, company:, role: "billing")

      expect(company.primary_contact).to eq(first_contact)
    end

    it "returns nil when the company has no contacts" do
      company = create(:company)

      expect(company.primary_contact).to be_nil
    end
  end
end

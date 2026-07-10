require "rails_helper"

RSpec.describe Contact, type: :model do
  describe "validations" do
    it "requires a name" do
      contact = build(:contact, name: nil)

      expect(contact).not_to be_valid
      expect(contact.errors[:name]).to include("can't be blank")
    end

    it "requires an email" do
      contact = build(:contact, email: nil)

      expect(contact).not_to be_valid
      expect(contact.errors[:email]).to include("can't be blank")
    end

    it "requires a valid email format" do
      contact = build(:contact, email: "not-an-email")

      expect(contact).not_to be_valid
      expect(contact.errors[:email]).to include("is invalid")
    end

    it "requires a role" do
      contact = build(:contact, role: nil)

      expect(contact).not_to be_valid
      expect(contact.errors[:role]).to include("can't be blank")
    end

    it "requires an allowed role" do
      contact = build(:contact, role: "sales")

      expect(contact).not_to be_valid
      expect(contact.errors[:role]).to include("is not included in the list")
    end

    it "requires a company" do
      contact = build(:contact, company: nil)

      expect(contact).not_to be_valid
      expect(contact.errors[:company]).to include("must exist")
    end
  end

  describe "associations" do
    it "belongs to a company" do
      company = build_stubbed(:company)
      contact = build_stubbed(:contact, company:)

      expect(contact.company).to eq(company)
    end
  end
end

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
end

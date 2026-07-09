require "rails_helper"

RSpec.describe SoftwareLicense, type: :model do
  describe "validations" do
    it "requires a software name" do
      software_license = build(:software_license, software_name: nil)

      expect(software_license).not_to be_valid
      expect(software_license.errors[:software_name]).to include("can't be blank")
    end

    it "requires an expiration date" do
      software_license = build(:software_license, expiration_date: nil)

      expect(software_license).not_to be_valid
      expect(software_license.errors[:expiration_date]).to include("can't be blank")
    end

    it "requires an asset" do
      software_license = build(:software_license, asset: nil)

      expect(software_license).not_to be_valid
      expect(software_license.errors[:asset]).to include("must exist")
    end
  end

  describe "associations" do
    it "belongs to an asset" do
      asset = build_stubbed(:asset)
      software_license = build_stubbed(:software_license, asset:)

      expect(software_license.asset).to eq(asset)
    end
  end

  describe "#expired?" do
    it "returns true when the expiration date is in the past" do
      software_license = build_stubbed(:software_license, expiration_date: 1.day.ago.to_date)

      expect(software_license).to be_expired
    end

    it "returns false when the expiration date is today" do
      software_license = build_stubbed(:software_license, expiration_date: Date.current)

      expect(software_license).not_to be_expired
    end

    it "returns false when the expiration date is in the future" do
      software_license = build_stubbed(:software_license, expiration_date: 1.day.from_now.to_date)

      expect(software_license).not_to be_expired
    end
  end

  describe "#days_until_expiration" do
    it "returns positive days for a future expiration date" do
      software_license = build_stubbed(:software_license, expiration_date: 30.days.from_now.to_date)

      expect(software_license.days_until_expiration).to eq(30)
    end

    it "returns zero for today's expiration date" do
      software_license = build_stubbed(:software_license, expiration_date: Date.current)

      expect(software_license.days_until_expiration).to eq(0)
    end

    it "returns negative days for a past expiration date" do
      software_license = build_stubbed(:software_license, expiration_date: 5.days.ago.to_date)

      expect(software_license.days_until_expiration).to eq(-5)
    end
  end
end

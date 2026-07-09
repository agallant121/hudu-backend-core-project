require "rails_helper"

RSpec.describe Asset, type: :model do
  describe "validations" do
    it "requires a name" do
      asset = build(:asset, name: nil)

      expect(asset).not_to be_valid
      expect(asset.errors[:name]).to include("can't be blank")
    end

    it "requires an asset type" do
      asset = build(:asset, asset_type: nil)

      expect(asset).not_to be_valid
      expect(asset.errors[:asset_type]).to include("can't be blank")
    end

    it "requires an allowed asset type" do
      asset = build(:asset, asset_type: "router")

      expect(asset).not_to be_valid
      expect(asset.errors[:asset_type]).to include("is not included in the list")
    end

    it "requires a unique serial number when present" do
      create(:asset, serial_number: "SN123456")
      asset = build(:asset, serial_number: "SN123456")

      expect(asset).not_to be_valid
      expect(asset.errors[:serial_number]).to include("has already been taken")
    end

    it "allows blank serial numbers" do
      asset = build(:asset, serial_number: nil)

      expect(asset).to be_valid
    end

    it "requires a company" do
      asset = build(:asset, company: nil)

      expect(asset).not_to be_valid
      expect(asset.errors[:company]).to include("must exist")
    end
  end

  describe "associations" do
    it "belongs to a company" do
      company = build_stubbed(:company)
      asset = build_stubbed(:asset, company:)

      expect(asset.company).to eq(company)
    end

    it "has many maintenance records" do
      asset = create(:asset)
      maintenance_record = create(:maintenance_record, asset:)

      expect(asset.maintenance_records).to contain_exactly(maintenance_record)
    end

    it "has many software licenses" do
      asset = create(:asset)
      software_license = create(:software_license, asset:)

      expect(asset.software_licenses).to contain_exactly(software_license)
    end
  end
end

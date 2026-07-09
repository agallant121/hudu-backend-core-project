require "rails_helper"

RSpec.describe MaintenanceRecord, type: :model do
  describe "validations" do
    it "requires a description" do
      maintenance_record = build(:maintenance_record, description: nil)

      expect(maintenance_record).not_to be_valid
      expect(maintenance_record.errors[:description]).to include("can't be blank")
    end

    it "requires performed_at" do
      maintenance_record = build(:maintenance_record, performed_at: nil)

      expect(maintenance_record).not_to be_valid
      expect(maintenance_record.errors[:performed_at]).to include("can't be blank")
    end

    it "requires a cost" do
      maintenance_record = build(:maintenance_record, cost: nil)

      expect(maintenance_record).not_to be_valid
      expect(maintenance_record.errors[:cost]).to include("can't be blank")
    end

    it "requires a numeric cost" do
      maintenance_record = build(:maintenance_record, cost: "not numeric")

      expect(maintenance_record).not_to be_valid
      expect(maintenance_record.errors[:cost]).to include("is not a number")
    end

    it "requires a non-negative cost" do
      maintenance_record = build(:maintenance_record, cost: -1)

      expect(maintenance_record).not_to be_valid
      expect(maintenance_record.errors[:cost]).to include("must be greater than or equal to 0")
    end

    it "requires an asset" do
      maintenance_record = build(:maintenance_record, asset: nil)

      expect(maintenance_record).not_to be_valid
      expect(maintenance_record.errors[:asset]).to include("must exist")
    end
  end

  describe "associations" do
    it "belongs to an asset" do
      asset = build_stubbed(:asset)
      maintenance_record = build_stubbed(:maintenance_record, asset:)

      expect(maintenance_record.asset).to eq(asset)
    end
  end
end

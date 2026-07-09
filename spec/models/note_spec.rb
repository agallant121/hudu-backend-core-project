require "rails_helper"

RSpec.describe Note, type: :model do
  describe "validations" do
    it "requires content" do
      note = build(:note, content: nil)

      expect(note).not_to be_valid
      expect(note.errors[:content]).to include("can't be blank")
    end

    it "requires an asset" do
      note = build(:note, asset: nil)

      expect(note).not_to be_valid
      expect(note.errors[:asset]).to include("must exist")
    end

    it "requires an author" do
      note = build(:note, author: nil)

      expect(note).not_to be_valid
      expect(note.errors[:author]).to include("must exist")
    end
  end

  describe "associations" do
    it "belongs to an asset" do
      asset = build_stubbed(:asset)
      note = build_stubbed(:note, asset:)

      expect(note.asset).to eq(asset)
    end

    it "belongs to an author" do
      author = build_stubbed(:user)
      note = build_stubbed(:note, author:)

      expect(note.author).to eq(author)
    end
  end
end

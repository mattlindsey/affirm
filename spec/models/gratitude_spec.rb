require "rails_helper"

RSpec.describe Gratitude, type: :model do
  subject(:gratitude) { build(:gratitude, content: "I am grateful for this test") }

  it { is_expected.to validate_presence_of(:content) }

  it "is valid with valid content" do
    expect(gratitude).to be_valid
  end

  it "is invalid with nil content" do
    gratitude.content = nil
    expect(gratitude).not_to be_valid
    expect(gratitude.errors[:content]).to include("can't be blank")
  end

  it "is invalid with empty content" do
    gratitude.content = ""
    expect(gratitude).not_to be_valid
    expect(gratitude.errors[:content]).to include("can't be blank")
  end

  it "is invalid with whitespace-only content" do
    gratitude.content = "   "
    expect(gratitude).not_to be_valid
    expect(gratitude.errors[:content]).to include("can't be blank")
  end

  it "saves with valid content" do
    expect { gratitude.save }.to change(Gratitude, :count).by(1)
  end

  it "has a created_at timestamp after saving" do
    gratitude.save
    expect(gratitude.created_at).not_to be_nil
  end

  it "has an updated_at timestamp after saving" do
    gratitude.save
    expect(gratitude.updated_at).not_to be_nil
  end

  it "allows long content" do
    gratitude.content = "I am grateful for " + ("a" * 1000)
    expect(gratitude).to be_valid
  end

  it "allows special characters in content" do
    gratitude.content = "I'm grateful for: coffee ☕, music 🎵, and friends! ❤️"
    expect(gratitude).to be_valid
  end
end

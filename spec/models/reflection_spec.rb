require "rails_helper"

RSpec.describe Reflection, type: :model do
  subject(:reflection) { build(:reflection) }

  describe "associations" do
    it { is_expected.to belong_to(:mood_check_in) }
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(reflection).to be_valid
    end

    it "is valid without content (content is optional)" do
      reflection.content = nil
      expect(reflection).to be_valid
    end

    it "is valid with empty content" do
      reflection.content = ""
      expect(reflection).to be_valid
    end

    it "is invalid without mood_check_in" do
      reflection.mood_check_in = nil
      expect(reflection).not_to be_valid
      expect(reflection.errors[:mood_check_in]).to include("must exist")
    end
  end

  describe "persistence" do
    it "saves with valid attributes" do
      expect { reflection.save }.to change(described_class, :count).by(1)
    end

    it "has timestamps after saving" do
      reflection.save
      expect(reflection.created_at).to be_present
      expect(reflection.updated_at).to be_present
    end
  end

  describe "with actual content" do
    it "saves and retrieves content correctly" do
      reflection.content = "Today I learned about gratitude and its impact on well-being"
      reflection.save

      saved = described_class.last
      expect(saved.content).to eq("Today I learned about gratitude and its impact on well-being")
    end

    it "allows long content" do
      reflection.content = "A" * 10_000
      expect(reflection).to be_valid
    end

    it "allows special characters and emojis" do
      reflection.content = "I reflected on gratitude 🙏, mindfulness 🧘, and growth 🌱!"
      expect(reflection).to be_valid
    end
  end
end

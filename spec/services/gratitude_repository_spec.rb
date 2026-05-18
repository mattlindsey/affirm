require "rails_helper"

RSpec.describe GratitudeRepository, type: :model do
  subject(:repository) { GratitudeRepository.new }

  describe "#yesterday_gratitude" do
    it "returns yesterday's gratitude when it exists" do
      yesterday_gratitude = Gratitude.create!(content: "coffee with Sarah")
      yesterday_gratitude.update_column(:created_at, 1.day.ago)
      today_gratitude = Gratitude.create!(content: "today's gratitude")

      expect(repository.yesterday_gratitude).to eq(yesterday_gratitude)
      expect(repository.yesterday_gratitude).not_to eq(today_gratitude)
    end

    it "returns nil when no yesterday's gratitude exists" do
      Gratitude.create!(content: "today's gratitude")
      expect(repository.yesterday_gratitude).to be_nil
    end

    it "returns the first gratitude when multiple exist from yesterday" do
      first = Gratitude.create!(content: "first gratitude")
      first.update_column(:created_at, 1.day.ago)
      second = Gratitude.create!(content: "second gratitude")
      second.update_column(:created_at, 1.day.ago + 1.hour)

      expect(repository.yesterday_gratitude).to eq(first)
    end
  end

  describe "#recent_gratitudes" do
    before { Gratitude.destroy_all }

    it "returns gratitudes in descending order" do
      old = Gratitude.create!(content: "old gratitude")
      old.update_column(:created_at, 3.days.ago)
      recent = Gratitude.create!(content: "recent gratitude")
      recent.update_column(:created_at, 1.day.ago)
      newest = Gratitude.create!(content: "newest gratitude")

      result = repository.recent_gratitudes(limit: 2)
      expect(result.count).to eq(2)
      expect(result.first).to eq(newest)
      expect(result.second).to eq(recent)
    end

    it "respects the limit parameter" do
      5.times { |i| Gratitude.create!(content: "gratitude #{i}").update_column(:created_at, i.days.ago) }

      expect(repository.recent_gratitudes(limit: 3).count).to eq(3)
    end

    it "returns all gratitudes when limit exceeds count" do
      2.times { |i| Gratitude.create!(content: "gratitude #{i}") }

      expect(repository.recent_gratitudes(limit: 5).count).to eq(2)
    end

    it "returns empty when no gratitudes exist" do
      expect(repository.recent_gratitudes).to be_empty
    end
  end
end

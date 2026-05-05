require "rails_helper"

RSpec.describe GreetingService, type: :model do
  subject(:service) { GreetingService.new }

  it "returns a Greeting with a time-based message" do
    greeting = service.call
    expect(greeting).to be_a(Greeting)
    expect(greeting.message).to be_present
    expect(greeting.message).to include("Good")
  end

  it "returns morning greeting in morning hours" do
    travel_to Time.zone.parse("2024-01-01 08:00:00") do
      expect(service.call.message).to include("Good morning!")
    end
  end

  it "returns afternoon greeting in afternoon hours" do
    travel_to Time.zone.parse("2024-01-01 14:00:00") do
      expect(service.call.message).to include("Good afternoon!")
    end
  end

  it "returns evening greeting in evening hours" do
    travel_to Time.zone.parse("2024-01-01 19:00:00") do
      expect(service.call.message).to include("Good evening!")
    end
  end

  it "returns night greeting in night hours" do
    travel_to Time.zone.parse("2024-01-01 23:00:00") do
      expect(service.call.message).to include("Good night!")
    end
  end

  it "includes past gratitude when available" do
    yesterday_gratitude = Gratitude.create!(content: "coffee with Sarah")
    yesterday_gratitude.update_column(:created_at, 1.day.ago)

    greeting = service.call
    expect(greeting.has_past_gratitude?).to be true
    expect(greeting.message).to include("coffee with Sarah")
    expect(greeting.message).to include("☕")
  end

  it "includes an inspirational quote when no past gratitude exists" do
    Gratitude.destroy_all

    greeting = service.call
    expect(greeting.has_past_gratitude?).to be false
    expect(greeting.message).to be_present

    quotes = [
      "Today is a new opportunity to be grateful! 🌟",
      "Every moment is a chance to appreciate something beautiful. ✨",
      "Start your day with gratitude and watch magic happen. 🪄",
      "The best way to start the day is with a grateful heart. 💖",
      "Your positive energy can change the world today. 🌍"
    ]
    expect(quotes.any? { |q| greeting.message.include?(q) }).to be true
  end

  it "accepts a custom gratitude repository" do
    custom_repository = Object.new
    def custom_repository.yesterday_gratitude = nil

    service = GreetingService.new(gratitude_repository: custom_repository)
    expect(service.call).to be_a(Greeting)
  end

  it "provides separated greeting components" do
    travel_to Time.zone.parse("2024-01-01 09:00:00") do
      greeting = service.call
      expect(greeting.time_based_message).to eq("Good morning!")
      expect(greeting.personalized_message).to be_present
      expect(greeting.message).to include(greeting.time_based_message)
    end
  end

  describe ".gratitude_prompts" do
    it "returns an array of strings" do
      prompts = GreetingService.gratitude_prompts
      expect(prompts).to be_an(Array)
      expect(prompts.length).to be > 0
      expect(prompts).to all(be_a(String))
      expect(prompts).to include("Who are you grateful for this week?")
    end

    it "can be sampled" do
      expect(GreetingService.gratitude_prompts.sample).to be_a(String).and be_present
    end
  end
end

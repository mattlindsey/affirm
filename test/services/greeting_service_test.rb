require "test_helper"

class GreetingServiceTest < ActiveSupport::TestCase
  def setup
    @service = GreetingService.new
  end

  test "should return greeting with time-based message" do
    greeting = @service.call

    assert_instance_of Greeting, greeting
    assert greeting.message.present?
    assert greeting.message.include?("Good")
  end

  test "should return morning greeting in morning hours" do
    travel_to Time.zone.parse("2024-01-01 08:00:00") do
      greeting = @service.call
      assert greeting.message.include?("Good morning!")
    end
  end

  test "should return afternoon greeting in afternoon hours" do
    travel_to Time.zone.parse("2024-01-01 14:00:00") do
      greeting = @service.call
      assert greeting.message.include?("Good afternoon!")
    end
  end

  test "should return evening greeting in evening hours" do
    travel_to Time.zone.parse("2024-01-01 19:00:00") do
      greeting = @service.call
      assert greeting.message.include?("Good evening!")
    end
  end

  test "should return night greeting in night hours" do
    travel_to Time.zone.parse("2024-01-01 23:00:00") do
      greeting = @service.call
      assert greeting.message.include?("Good night!")
    end
  end

  test "should include past gratitude when available" do
    # Create a gratitude from yesterday
    yesterday_gratitude = Gratitude.create!(content: "coffee with Sarah")
    yesterday_gratitude.update_column(:created_at, 1.day.ago)

    greeting = @service.call

    assert greeting.has_past_gratitude?
    assert greeting.message.include?("coffee with Sarah")
    assert greeting.message.include?("☕")
  end

  test "should include inspirational quote when no past gratitude" do
    # Ensure no gratitudes exist
    Gratitude.destroy_all

    greeting = @service.call

    assert_not greeting.has_past_gratitude?
    assert greeting.message.present?
    # Should contain one of the inspirational quotes
    quotes = [
      "Today is a new opportunity to be grateful! 🌟",
      "Every moment is a chance to appreciate something beautiful. ✨",
      "Start your day with gratitude and watch magic happen. 🪄",
      "The best way to start the day is with a grateful heart. 💖",
      "Your positive energy can change the world today. 🌍"
    ]
    assert quotes.any? { |quote| greeting.message.include?(quote) }
  end

  test "should use custom gratitude repository" do
    # Create a simple mock object
    custom_repository = Object.new
    def custom_repository.yesterday_gratitude
      nil
    end

    service = GreetingService.new(gratitude_repository: custom_repository)
    greeting = service.call

    assert_instance_of Greeting, greeting
  end

  test "provides separated greeting components" do
    travel_to Time.zone.parse("2024-01-01 09:00:00") do
      greeting = @service.call

      assert_equal "Good morning!", greeting.time_based_message
      assert greeting.personalized_message.present?
      assert greeting.message.include? greeting.time_based_message
    end
  end
end

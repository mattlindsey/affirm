class GreetingService
  def initialize(gratitude_repository: GratitudeRepository.new)
    @gratitude_repository = gratitude_repository
  end

  def call
    Greeting.new(
      message: full_message,
      time_based_message: time_based_greeting,
      personalized_message: personalized_message,
      past_gratitude: past_gratitude
    )
  end

  private

  attr_reader :gratitude_repository

  def full_message
    "#{time_based_greeting} #{personalized_message}"
  end

  def time_based_greeting
    current_hour = Time.current.hour

    case current_hour
    when 5..11
      "Good morning!"
    when 12..17
      "Good afternoon!"
    when 18..22
      "Good evening!"
    else
      "Good night!"
    end
  end

  def personalized_message
    if past_gratitude
      "Yesterday you were grateful for: #{past_gratitude.content} ☕"
    else
      inspirational_quote
    end
  end

  def past_gratitude
    @past_gratitude ||= gratitude_repository.yesterday_gratitude
  end

  def inspirational_quote
    quotes.sample
  end

  def quotes
    [
      "Today is a new opportunity to be grateful! 🌟",
      "Every moment is a chance to appreciate something beautiful. ✨",
      "Start your day with gratitude and watch magic happen. 🪄",
      "The best way to start the day is with a grateful heart. 💖",
      "Your positive energy can change the world today. 🌍"
    ]
  end
end

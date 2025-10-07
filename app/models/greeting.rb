class Greeting
  attr_reader :message, :past_gratitude, :time_based_message, :personalized_message

  def initialize(message:, past_gratitude: nil, time_based_message: nil, personalized_message: nil)
    @message = message
    @past_gratitude = past_gratitude
    @time_based_message = time_based_message
    @personalized_message = personalized_message
  end

  def has_past_gratitude?
    past_gratitude.present?
  end
end

class Greeting
  attr_reader :message, :past_gratitude

  def initialize(message:, past_gratitude: nil)
    @message = message
    @past_gratitude = past_gratitude
  end

  def has_past_gratitude?
    past_gratitude.present?
  end
end






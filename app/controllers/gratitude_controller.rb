class GratitudeController < ApplicationController
  def index
    @gratitudes = Gratitude.order(created_at: :desc)
  end

  def random
    @gratitude = Gratitude.order("RANDOM()").first
  end

  def prompt
    @current_prompt = GreetingService.gratitude_prompts.sample
  end

  private

  def ai
    if params[:generate]
      @ai_prompt = Gratitude.generate_ai_prompt
      @error = @ai_affirmation ? nil : "Unable to generate prompt. Please check your API key and try again."
    end
  end
end

class GratitudeController < ApplicationController
  def index
    @gratitudes = current_user.gratitudes.order(created_at: :desc)
  end

  def random
    @gratitude = current_user.gratitudes.order("RANDOM()").first
  end

  def prompt
    @current_prompt = GreetingService.gratitude_prompts.sample
  end
end

class AffirmationsController < ApplicationController
  def index
    @affirmations = Affirmation.all
  end

  def random
    @affirmation = Affirmation.order("RANDOM()").first
  end

  def ai
    if params[:generate]
      @ai_affirmation = Affirmation.generate_ai_affirmation
      @error = @ai_affirmation ? nil : "Unable to generate affirmation. Please check your API key and try again."
    end
  end

  def destroy
    @affirmation = Affirmation.find(params[:id])
    @affirmation.destroy
    redirect_to affirmations_path, notice: "Affirmation was successfully deleted."
  end
end

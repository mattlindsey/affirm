class AffirmationsController < ApplicationController
  def index
    @affirmations = Affirmation.order(created_at: :desc)
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

  def create
    @affirmation = Affirmation.new(affirmation_params)
    if @affirmation.save
      redirect_to affirmations_path, notice: "Affirmation saved successfully."
    else
      redirect_to ai_affirmation_path, alert: "Failed to save affirmation."
    end
  end

  def destroy
    @affirmation = Affirmation.find(params[:id])
    @affirmation.destroy
    redirect_to affirmations_path, notice: "Affirmation was successfully deleted."
  end

  private

  def affirmation_params
    params.require(:affirmation).permit(:content)
  end
end

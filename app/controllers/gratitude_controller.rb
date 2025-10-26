class GratitudeController < ApplicationController
  def index
    @gratitudes = Gratitude.order(created_at: :asc)
  end

  def random
    @gratitude = Gratitude.order("RANDOM()").first
  end

  def prompt
    @prompts = [
      "Who are you grateful for this week?",
      "What experience made you smile today?",
      "What's something you're looking forward to?",
      "What's a small joy you experienced recently?",
      "Who has helped you recently and how?",
      "What's something beautiful you noticed today?",
      "What's a challenge you're grateful to have overcome?",
      "What's something you love about where you live?"
    ]
    @current_prompt = @prompts.sample
  end

  def create
    # Simple action to render the form
  end

  def store
    if create_gratitudes
      redirect_to gratitude_path, notice: "Today's gratitudes created successfully!"
    else
      render :create, status: :unprocessable_content
    end
  end

  private

  def create_gratitudes
    begin
      params = gratitude_params
      return false unless params[:contents].is_a?(Array)

      params[:contents].each do |content|
        next if content.blank?

        gratitude = Gratitude.new(content: content.strip)
        return false unless gratitude.save
      end
      true
    rescue ActionController::ParameterMissing
      false
    end
  end

  def gratitude_params
    params.require(:gratitude).permit(contents: [])
  end

  def ai
    if params[:generate]
      @ai_prompt = Gratitude.generate_ai_prompt
      @error = @ai_affirmation ? nil : "Unable to generate prompt. Please check your API key and try again."
    end
  end
end


class GratitudeController < ApplicationController
  before_action :set_gratitude, only: [:destroy]

  def index
    @gratitudes = Gratitude.order(created_at: :asc)
  end

  def random
    @gratitude = Gratitude.order("RANDOM()").first
  end

  def prompt
    @prompts = [
      "Who are you grateful for this week?",
      "What experience made you smile today?",
      "What's something you're looking forward to?",
      "What's a small joy you experienced recently?",
      "Who has helped you recently and how?",
      "What's something beautiful you noticed today?",
      "What's a challenge you're grateful to have overcome?",
      "What's something you love about where you live?"
    ]
    @current_prompt = @prompts.sample
  end

  def create
    # Simple action to render the form
  end

  def store
    if create_gratitudes
      redirect_to gratitudes_path, notice: "Today's gratitudes created successfully!"
    else
      render :create, status: :unprocessable_content
    end
  end

  def destroy
    @gratitude.destroy
    redirect_to gratitudes_path, notice: "Gratitude was successfully deleted.", status: :see_other
  end

  private

  def set_gratitude
    @gratitude = Gratitude.find(params[:id])
  end

  def create_gratitudes
    begin
      params = gratitude_params
      return false unless params[:contents].is_a?(Array)

      params[:contents].each do |content|
        next if content.blank?

        gratitude = Gratitude.new(content: content.strip)
        return false unless gratitude.save
      end
      true
    rescue ActionController::ParameterMissing
      false
    end
  end

  def gratitude_params
    params.require(:gratitude).permit(contents: [])
  end

  def ai
    if params[:generate]
      @ai_prompt = Gratitude.generate_ai_prompt
      @error = @ai_prompt ? nil : "Unable to generate prompt. Please check your API key and try again."
    end
  end
end
class DailyFlowController < ApplicationController
  before_action :set_today

  # Step 1: Start the daily flow
  def start
    redirect_to action: :check_in
  end

  # Step 2: Check-in (mood tracking)
  def check_in
    @greeting = GreetingService.new.call
    @mood_check_in = MoodCheckIn.new
  end

  def save_check_in
    @mood_check_in = MoodCheckIn.new(mood_params)
    
    if @mood_check_in.save
      redirect_to action: :affirmation
    else
      @greeting = GreetingService.new.call
      render :check_in, status: :unprocessable_content
    end
  end

  # Step 3: Show daily affirmation
  def affirmation
    @affirmation = Affirmation.order("RANDOM()").first
  end

  # Step 4: Capture gratitudes
  def gratitude
    @current_prompt = GreetingService.gratitude_prompts.sample
  end

  def save_gratitude
    if create_gratitudes
      redirect_to action: :reflection
    else
      @current_prompt = GreetingService.gratitude_prompts.sample
      render :gratitude, status: :unprocessable_content
    end
  end

  # Step 5: Reflection - show today's gratitudes and ask for reflection
  def reflection
    @todays_gratitudes = Gratitude.where("DATE(created_at) = ?", @today).order(created_at: :desc).limit(3)
  end

  def save_reflection
    # For now, we'll just redirect to completion
    # In the future, this could save reflection notes
    redirect_to action: :completion
  end

  # Step 6: Completion screen
  def completion
    @todays_mood = MoodCheckIn.where("DATE(created_at) = ?", @today).last
    @todays_gratitudes = Gratitude.where("DATE(created_at) = ?", @today).order(created_at: :desc).limit(3)
  end

  private

  def set_today
    @today = Date.current
  end

  def mood_params
    params.require(:mood_check_in).permit(:mood_level, :notes)
  end

  def create_gratitudes
    begin
      params_data = gratitude_params
      return false unless params_data[:contents].is_a?(Array)

      params_data[:contents].each do |content|
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
end

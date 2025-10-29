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
    @mood_check_in = if params[:mood_check_in_id].present?
                       MoodCheckIn.find_by(id: params[:mood_check_in_id])
                     else
                       MoodCheckIn.where("DATE(created_at) = ?", @today).last
                     end
    # Require reflection params and content; otherwise render the reflection form with errors
    begin
      reflection_data = reflection_params
    rescue ActionController::ParameterMissing
      @todays_gratitudes = Gratitude.where("DATE(created_at) = ?", @today).order(created_at: :desc).limit(3)
      return render :reflection, status: :unprocessable_entity
    end

    if reflection_data[:content].blank?
      @todays_gratitudes = Gratitude.where("DATE(created_at) = ?", @today).order(created_at: :desc).limit(3)
      return render :reflection, status: :unprocessable_entity
    end

    # Ensure we have a mood_check_in to attach to
    unless @mood_check_in
      @todays_gratitudes = Gratitude.where("DATE(created_at) = ?", @today).order(created_at: :desc).limit(3)
      return render :reflection, status: :unprocessable_entity
    end

    @reflection = @mood_check_in.reflections.build(reflection_data)
    @reflection.user = current_user if defined?(current_user)

    if @reflection.save
      redirect_to action: :completion
    else
      @todays_gratitudes = Gratitude.where("DATE(created_at) = ?", @today).order(created_at: :desc).limit(3)
      render :reflection, status: :unprocessable_entity
    end
  end

  # Step 6: Completion screen
  def completion
    @todays_mood = MoodCheckIn.where("DATE(created_at) = ?", @today).last
    @todays_gratitudes = Gratitude.where("DATE(created_at) = ?", @today).order(created_at: :desc).limit(3)
    @todays_reflections = Reflection.where("DATE(created_at) = ?", @today).order(created_at: :desc)
  end

  private

  def set_today
    @today = Date.current
  end

  def mood_params
    params.require(:mood_check_in).permit(:mood_level, :notes)
  end

  def reflection_params
    params.require(:reflection).permit(:content)
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

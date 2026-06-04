class DailyFlowController < ApplicationController
  before_action :set_today

  def start
    redirect_to action: :check_in
  end

  def check_in
    @greeting = GreetingService.new.call
    @mood_check_in = current_user.mood_check_ins.new
  end

  def save_check_in
    @mood_check_in = current_user.mood_check_ins.new(mood_params)

    if @mood_check_in.save
      redirect_to action: :affirmation
    else
      @greeting = GreetingService.new.call
      render :check_in, status: :unprocessable_content
    end
  end

  def affirmation
    @affirmation = Affirmation.for_user(current_user).order("RANDOM()").first
  end

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

  def reflection
    @todays_gratitudes = current_user.gratitudes
                                     .where("DATE(created_at) = ?", @today)
                                     .order(created_at: :desc)
                                     .limit(3)
  end

  def save_reflection
    @mood_check_in = if params[:mood_check_in_id].present?
                       current_user.mood_check_ins.find_by(id: params[:mood_check_in_id])
                     else
                       current_user.mood_check_ins.where("DATE(created_at) = ?", @today).last
                     end

    begin
      reflection_data = reflection_params
    rescue ActionController::ParameterMissing
      return redirect_to action: :completion
    end

    return redirect_to(action: :completion) if reflection_data[:content].blank?

    unless @mood_check_in
      return redirect_to action: :completion
    end

    @reflection = @mood_check_in.reflections.build(reflection_data)
    @reflection.user = current_user

    if @reflection.save
      redirect_to action: :completion
    else
      @todays_gratitudes = current_user.gratitudes
                                       .where("DATE(created_at) = ?", @today)
                                       .order(created_at: :desc)
                                       .limit(3)
      render :reflection, status: :unprocessable_entity
    end
  end

  def completion
    @todays_mood        = current_user.mood_check_ins.where("DATE(created_at) = ?", @today).last
    @todays_gratitudes  = current_user.gratitudes.where("DATE(created_at) = ?", @today).order(created_at: :desc).limit(3)
    @todays_reflections = current_user.reflections.where("DATE(created_at) = ?", @today).order(created_at: :desc)
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

        gratitude = current_user.gratitudes.new(content: content.strip)
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

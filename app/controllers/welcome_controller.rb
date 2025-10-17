class WelcomeController < ApplicationController
  def index
    @greeting = GreetingService.new.call
    @mood_check_in = MoodCheckIn.new
  end

  def create_mood
    @mood_check_in = MoodCheckIn.new(mood_params)

    if @mood_check_in.save
      redirect_to welcome_path, notice: "Mood recorded! Thanks for checking in. 😊"
    else
      @greeting = GreetingService.new.call
      render :index, status: :unprocessable_content
    end
  end

  private

  def mood_params
    params.require(:mood_check_in).permit(:mood_level, :notes)
  end
end

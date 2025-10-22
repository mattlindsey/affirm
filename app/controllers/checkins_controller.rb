class CheckinsController < ApplicationController
  def index
    scope = (defined?(current_user) && current_user) ? current_user.mood_check_ins : MoodCheckIn.all
    @checkins = scope.order(created_at: :desc)
    @total_count = @checkins.count
  end
end

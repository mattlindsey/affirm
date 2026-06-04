class ReflectionsController < ApplicationController
  def index
    @reflections = current_user.reflections.includes(:mood_check_in).order(created_at: :desc)
  end
end

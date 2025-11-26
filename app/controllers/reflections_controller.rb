class ReflectionsController < ApplicationController
  def index
    @reflections = Reflection.includes(:mood_check_in).order(created_at: :desc)
  end
end

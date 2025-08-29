class GratitudeController < ApplicationController
  def index
    @gratitudes = Gratitude.order(created_at: :asc)
  end

  def random
    @gratitude = Gratitude.order("RANDOM()").first
  end
end

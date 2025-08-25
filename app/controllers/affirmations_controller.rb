class AffirmationsController < ApplicationController
  def index
    @affirmations = Affirmation.all
  end
end

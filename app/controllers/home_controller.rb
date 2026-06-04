class HomeController < ApplicationController
  def index
    @name = current_user.setting&.name.presence || current_user.name.presence
  end
end

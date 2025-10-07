class HomeController < ApplicationController
  def index
    @name = session[:name]
  end
end

class HomeController < ApplicationController
  def index
    @name = Setting.instance.name.presence || session[:name]
  end
end

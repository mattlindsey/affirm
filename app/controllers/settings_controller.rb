class SettingsController < ApplicationController
  def index
    @name = session[:name]
  end

  def update
    session[:name] = params[:name]
    redirect_to root_path, notice: "Settings updated."
  end
end

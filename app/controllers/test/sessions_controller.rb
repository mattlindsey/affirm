class Test::SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def create
    session[:user_id] = params[:user_id].to_i
    redirect_to root_path
  end
end

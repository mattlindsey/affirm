class SessionsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    redirect_to root_path if user_signed_in?
  end

  def create
    user = User.find_by(email: params[:email]&.downcase)
    if user&.authenticate(params[:password])
      sign_in(user)
      redirect_back_or root_path
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def guest_login
    guest = User.find_by!(email: "random@random.com")
    sign_in(guest)
    redirect_to root_path
  end

  def destroy
    session.delete(:user_id)
    redirect_to login_path, notice: "You have been signed out."
  end

  def omniauth
    user = Auth::ProcessOauthCallbackService.call(request.env["omniauth.auth"])
    sign_in(user)
    redirect_back_or root_path
  end

  def oauth_failure
    flash[:alert] = "Google sign-in is temporarily unavailable. Please try again later."
    redirect_to login_path
  end

  private

  def sign_in(user)
    session[:user_id] = user.id
  end
end

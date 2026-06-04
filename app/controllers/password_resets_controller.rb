class PasswordResetsController < ApplicationController
  skip_before_action :authenticate_user!

  def new; end

  def create
    user = User.find_by(email: params[:email]&.downcase)
    PasswordResetMailer.reset(user).deliver_later if user
    redirect_to login_path,
      notice: "If that address is registered, a reset link is on its way."
  end

  def edit
    @user = User.find_by_token_for(:password_reset, params[:token])
    redirect_to password_reset_path, alert: "Reset link is invalid or expired." unless @user
  end

  def update
    @user = User.find_by_token_for(:password_reset, params[:token])
    unless @user
      redirect_to password_reset_path, alert: "Reset link is invalid or expired." and return
    end

    if @user.update(password_reset_params)
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Password updated. You are now signed in."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_reset_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end

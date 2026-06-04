class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :authenticate_user!

  helper_method :current_user, :user_signed_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def user_signed_in?
    current_user.present?
  end

  def authenticate_user!
    return if user_signed_in?
    response.headers["Cache-Control"] = "no-store"
    store_location
    redirect_to login_path, alert: "Please sign in to continue."
  end

  def store_location
    session[:return_to] = request.fullpath if request.get? || request.head?
  end

  def redirect_back_or(default)
    redirect_to(session.delete(:return_to) || default)
  end
end

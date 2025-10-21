class SettingsController < ApplicationController
  def index
    @setting = Setting.instance
  end

  def update
    @setting = Setting.instance
    if @setting.update(setting_params)
      session[:name] = @setting.name
      redirect_to settings_path, notice: "Settings updated successfully."
    else
      render :index
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:name)
  end
end

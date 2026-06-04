class SettingsController < ApplicationController
  def index
    @setting = current_user.setting || current_user.build_setting
  end

  def update
    @setting = current_user.setting || current_user.build_setting
    if @setting.update(setting_params)
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

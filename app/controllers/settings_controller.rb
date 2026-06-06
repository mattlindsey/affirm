class SettingsController < ApplicationController
  def index
    @setting = current_user.setting || current_user.build_setting
  end

  def update
    @setting = current_user.setting || current_user.build_setting
    attrs = setting_params
    attrs = attrs.except(:openai_api_key) if attrs[:openai_api_key].blank?
    if @setting.update(attrs)
      redirect_to settings_path, notice: "Settings updated successfully."
    else
      render :index
    end
  end

  def destroy_api_key
    setting = current_user.setting
    if setting&.openai_api_key_present?
      setting.update!(openai_api_key: nil)
      redirect_to settings_path, notice: "API key removed."
    else
      redirect_to settings_path
    end
  end

  private

  def setting_params
    params.require(:setting).permit(:name, :openai_api_key)
  end
end

require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  test "should get settings page" do
    get settings_url
    assert_response :success
    assert_select "h1", "Settings"
  end

  test "should save name in session and redirect" do
  # controller expects nested params[:setting][:name] when using form_with model
  post settings_url, params: { setting: { name: "Lucas" } }
  assert_equal "Lucas", @request.session[:name]
  assert_redirected_to settings_path
  follow_redirect!
  assert_select "h1", "Settings"
  end
end

require "rails_helper"

RSpec.describe "Settings", type: :request do
  it "gets settings page" do
    get settings_url
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Settings")
  end

  it "saves name in session and redirects" do
    post settings_url, params: { setting: { name: "Lucas" } }
    expect(session[:name]).to eq("Lucas")
    expect(response).to redirect_to(settings_path)

    follow_redirect!
    expect(response.body).to include("Settings")
  end
end

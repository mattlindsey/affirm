require "rails_helper"

RSpec.describe "Settings", type: :request do
  let(:user) { sign_in_test_user }

  before { user }

  it "gets settings page" do
    get settings_url
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Settings")
  end

  it "saves name and redirects" do
    post settings_url, params: { setting: { name: "Lucas" } }
    expect(response).to redirect_to(settings_path)

    follow_redirect!
    expect(response.body).to include("Settings")
  end

  describe "OpenAI API key" do
    describe "POST /settings" do
      context "when submitting a new key" do
        it "saves the key" do
          post settings_url, params: { setting: { openai_api_key: "sk-test-abc123" } }
          expect(response).to redirect_to(settings_path)
          expect(user.reload.setting.openai_api_key).to eq("sk-test-abc123")
        end

        it "shows the masked indicator after saving" do
          post settings_url, params: { setting: { openai_api_key: "sk-test-abc123" } }
          follow_redirect!
          expect(response.body).to include("sk-••••••••••••••••")
        end
      end

      context "when submitting a blank key with an existing key saved" do
        before do
          user.create_setting(openai_api_key: "sk-existing-key")
        end

        it "preserves the existing key" do
          post settings_url, params: { setting: { openai_api_key: "" } }
          expect(user.reload.setting.openai_api_key).to eq("sk-existing-key")
        end
      end

      context "when no key is saved" do
        it "does not show the masked indicator" do
          get settings_url
          expect(response.body).not_to include("sk-••••••••••••••••")
        end

        it "does not show the Remove API Key button" do
          get settings_url
          expect(response.body).not_to include("Remove API Key")
        end
      end

      context "when a key is saved" do
        before do
          user.create_setting(openai_api_key: "sk-existing-key")
        end

        it "shows the masked indicator" do
          get settings_url
          expect(response.body).to include("sk-••••••••••••••••")
        end

        it "does not render the raw key in the page" do
          get settings_url
          expect(response.body).not_to include("sk-existing-key")
        end

        it "shows the Remove API Key button" do
          get settings_url
          expect(response.body).to include("Remove API Key")
        end
      end
    end

    describe "DELETE /settings/api_key" do
      context "when a key is saved" do
        before do
          user.create_setting(openai_api_key: "sk-existing-key")
        end

        it "clears the key" do
          delete settings_api_key_url
          expect(user.reload.setting.openai_api_key).to be_nil
        end

        it "redirects to settings with a notice" do
          delete settings_api_key_url
          expect(response).to redirect_to(settings_path)
          follow_redirect!
          expect(response.body).to include("API key removed")
        end
      end

      context "when no key is saved" do
        it "redirects without error" do
          delete settings_api_key_url
          expect(response).to redirect_to(settings_path)
        end
      end
    end
  end
end

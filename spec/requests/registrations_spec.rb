require "rails_helper"

RSpec.describe "Registrations", type: :request do
  describe "GET /signup" do
    context "when not signed in" do
      it "returns 200" do
        get signup_path
        expect(response).to have_http_status(:ok)
      end
    end

    context "when already signed in" do
      before do
        post signup_path, params: {
          user: { email: "signed_in@example.com", password: "password123", password_confirmation: "password123" }
        }
      end

      it "redirects to root" do
        get signup_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /signup" do
    context "with valid params" do
      let(:params) do
        { user: { email: "new@example.com", password: "password123", password_confirmation: "password123" } }
      end

      it "creates a user and redirects to root" do
        expect { post signup_path, params: params }.to change(User, :count).by(1)
        expect(response).to redirect_to(root_path)
      end

      it "sets the session" do
        post signup_path, params: params
        expect(session[:user_id]).to eq(User.last.id)
      end
    end

    context "with a duplicate email" do
      let!(:existing) { create(:user, email: "taken@example.com") }

      it "returns 422 and shows an error" do
        post signup_path, params: { user: { email: "taken@example.com", password: "password123", password_confirmation: "password123" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Email")
      end
    end

    context "with a password shorter than 8 characters" do
      it "returns 422" do
        post signup_path, params: { user: { email: "new@example.com", password: "short", password_confirmation: "short" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with mismatched password confirmation" do
      it "returns 422" do
        post signup_path, params: { user: { email: "new@example.com", password: "password123", password_confirmation: "different" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "unauthenticated redirect" do
    it "redirects unauthenticated GET /daily_flow to /login" do
      get daily_flow_path
      expect(response).to redirect_to(login_path)
    end

    it "redirects unauthenticated GET /affirmations to /login" do
      get affirmations_path
      expect(response).to redirect_to(login_path)
    end
  end
end

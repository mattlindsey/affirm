require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { create(:user) }

  describe "GET /login" do
    it "returns 200" do
      get login_path
      expect(response).to have_http_status(:ok)
    end

    context "when already signed in" do
      before { sign_in_as(user) }

      it "redirects to root" do
        get login_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /login" do
    context "with correct credentials" do
      it "sets session and redirects to root" do
        post login_path, params: { email: user.email, password: "password123" }
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(root_path)
      end

      it "redirects to the originally requested page" do
        get affirmations_path
        post login_path, params: { email: user.email, password: "password123" }
        expect(response).to redirect_to(affirmations_path)
      end
    end

    context "with wrong password" do
      it "returns 422 with a generic error" do
        post login_path, params: { email: user.email, password: "wrongpassword" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Invalid email or password")
      end

      it "does not reveal which field is wrong" do
        post login_path, params: { email: "unknown@example.com", password: "whatever" }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Invalid email or password")
      end
    end

    context "after 10 consecutive failures" do
      before do
        10.times { post login_path, params: { email: user.email, password: "wrong" } }
      end

      it "returns 429 on the eleventh attempt" do
        post login_path, params: { email: user.email, password: "wrong" }
        expect(response).to have_http_status(:too_many_requests)
      end

      it "includes a lockout message in the response body" do
        post login_path, params: { email: user.email, password: "wrong" }
        expect(response.body).to include("Too many sign-in attempts")
      end
    end
  end

  describe "DELETE /logout" do
    before { sign_in_as(user) }

    it "clears the session and redirects to login" do
      delete logout_path
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(login_path)
    end
  end

  describe "Google OAuth callback (GET /auth/google_oauth2/callback)" do
    context "with a brand-new Google user" do
      before { mock_google_auth(uid: "new_uid", email: "newgoogle@example.com", name: "New User") }

      it "creates a user, sets session, and redirects to root" do
        expect { get "/auth/google_oauth2/callback" }.to change(User, :count).by(1)
        expect(session[:user_id]).to eq(User.last.id)
        expect(response).to redirect_to(root_path)
      end
    end

    context "with a returning Google user (same google_uid)" do
      let!(:existing) { create(:user, :google_only, google_uid: "existing_uid", email: "returning@example.com") }

      before { mock_google_auth(uid: "existing_uid", email: "returning@example.com") }

      it "does not create a duplicate user" do
        expect { get "/auth/google_oauth2/callback" }.not_to change(User, :count)
      end

      it "signs in the existing user" do
        get "/auth/google_oauth2/callback"
        expect(session[:user_id]).to eq(existing.id)
      end
    end

    context "when Google email matches an existing email/password account" do
      let!(:email_user) { create(:user, email: "linked@example.com") }

      before { mock_google_auth(uid: "link_uid", email: "linked@example.com") }

      it "auto-links the Google identity to the existing account" do
        get "/auth/google_oauth2/callback"
        expect(email_user.reload.google_uid).to eq("link_uid")
      end

      it "signs in the existing user" do
        get "/auth/google_oauth2/callback"
        expect(session[:user_id]).to eq(email_user.id)
      end
    end
  end

  describe "GET /auth/failure" do
    it "redirects to login with an alert" do
      get "/auth/failure"
      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to include("temporarily unavailable")
    end
  end

  private

  def sign_in_as(user)
    post signup_path, params: {
      user: { email: "signin_#{user.id}@example.com", password: "password123", password_confirmation: "password123" }
    }
  end
end

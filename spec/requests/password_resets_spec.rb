require "rails_helper"

RSpec.describe "PasswordResets", type: :request do
  let(:user) { create(:user) }

  describe "POST /password_reset" do
    context "with a registered email" do
      it "redirects to login with a neutral notice" do
        post password_reset_path, params: { email: user.email }
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to include("on its way")
      end

      it "enqueues a password reset email" do
        expect {
          post password_reset_path, params: { email: user.email }
        }.to have_enqueued_mail(PasswordResetMailer, :reset)
      end
    end

    context "with an unknown email" do
      it "still redirects with the same neutral notice (no info leak)" do
        post password_reset_path, params: { email: "unknown@example.com" }
        expect(response).to redirect_to(login_path)
        expect(flash[:notice]).to include("on its way")
      end

      it "does not enqueue any email" do
        expect {
          post password_reset_path, params: { email: "unknown@example.com" }
        }.not_to have_enqueued_mail
      end
    end
  end

  describe "GET /password_reset/edit" do
    context "with a valid token" do
      let(:token) { user.generate_token_for(:password_reset) }

      it "returns 200" do
        get edit_password_reset_path(token: token)
        expect(response).to have_http_status(:ok)
      end
    end

    context "with an invalid token" do
      it "redirects to password_reset with an alert" do
        get edit_password_reset_path(token: "invalid")
        expect(response).to redirect_to(password_reset_path)
        expect(flash[:alert]).to include("invalid or expired")
      end
    end
  end

  describe "PATCH /password_reset" do
    let(:token) { user.generate_token_for(:password_reset) }

    context "with valid token and new password" do
      it "updates the password and signs the user in" do
        patch password_reset_path, params: {
          token: token,
          user: { password: "newpassword1", password_confirmation: "newpassword1" }
        }
        expect(session[:user_id]).to eq(user.id)
        expect(response).to redirect_to(root_path)
      end

      it "invalidates the old token after update" do
        patch password_reset_path, params: {
          token: token,
          user: { password: "newpassword1", password_confirmation: "newpassword1" }
        }
        expect(User.find_by_token_for(:password_reset, token)).to be_nil
      end
    end

    context "with an invalid token" do
      it "redirects to password_reset with an alert" do
        patch password_reset_path, params: {
          token: "tampered",
          user: { password: "newpassword1", password_confirmation: "newpassword1" }
        }
        expect(response).to redirect_to(password_reset_path)
      end
    end

    context "with a weak new password" do
      it "returns 422 with validation errors" do
        patch password_reset_path, params: {
          token: token,
          user: { password: "weak", password_confirmation: "weak" }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end

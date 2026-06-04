require "rails_helper"

RSpec.describe "Data isolation", type: :request do
  let(:alice) { create(:user) }
  let(:bob)   { create(:user) }

  describe "affirmations" do
    let!(:alice_affirmation) { create(:affirmation, user: alice, content: "Alice only content") }
    let!(:bob_affirmation)   { create(:affirmation, user: bob,   content: "Bob only content") }

    context "when signed in as Alice" do
      before { post login_path, params: { email: alice.email, password: "password123" } }

      it "shows only Alice's affirmations" do
        get affirmations_path
        expect(response.body).to include("Alice only content")
        expect(response.body).not_to include("Bob only content")
      end
    end

    context "when unauthenticated" do
      it "redirects to login" do
        get affirmations_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "attempting to destroy another user's affirmation" do
      before { post login_path, params: { email: alice.email, password: "password123" } }

      it "returns 404" do
        delete affirmation_path(bob_affirmation)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

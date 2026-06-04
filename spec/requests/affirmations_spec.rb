require "rails_helper"

RSpec.describe "Affirmations", type: :request do
  let(:signed_in_user) { sign_in_test_user }
  before { signed_in_user }
  let(:affirmation) { create(:affirmation, user: signed_in_user) }

  it "gets index" do
    get affirmations_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Daily Affirmations")
  end

  it "deletes an affirmation" do
    affirmation
    expect { delete affirmation_path(affirmation) }.to change(Affirmation, :count).by(-1)
    expect(response).to redirect_to(affirmations_path)
    expect(flash[:notice]).to eq("Affirmation was successfully deleted.")
  end
end

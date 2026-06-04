require "rails_helper"

RSpec.describe "Checkins", type: :request do
  let(:signed_in_user) { sign_in_test_user }
  before do
    signed_in_user
    MoodCheckIn.destroy_all
  end

  it "gets index and shows empty state message" do
    get checkins_path
    expect(response).to have_http_status(:success)
    expect(response.body).to match(/Your check-ins/)
    expect(response.body).to match(/don't have any check-ins yet/i)
  end

  it "lists existing checkins" do
    create(:mood_check_in, mood_level: 7, notes: "Feeling good", user: signed_in_user)
    create(:mood_check_in, mood_level: 3, notes: "A bit low", user: signed_in_user)

    get checkins_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("7/10")
  end
end

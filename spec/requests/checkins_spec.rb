require "rails_helper"

RSpec.describe "Checkins", type: :request do
  before { MoodCheckIn.destroy_all }

  it "gets index and shows empty state message" do
    get checkins_path
    expect(response).to have_http_status(:success)
    expect(response.body).to match(/Your check-ins/)
    expect(response.body).to match(/don't have any check-ins yet/i)
  end

  it "lists existing checkins" do
    create(:mood_check_in, mood_level: 7, notes: "Feeling good")
    create(:mood_check_in, mood_level: 3, notes: "A bit low")

    get checkins_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("7/10")
  end
end

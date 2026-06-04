require "rails_helper"

RSpec.describe "CheckinsChart", type: :request do
  let(:signed_in_user) { sign_in_test_user }
  before do
    signed_in_user
    MoodCheckIn.destroy_all
    create(:mood_check_in, mood_level: 5, created_at: Time.zone.now.beginning_of_month + 1.day, user: signed_in_user)
    create(:mood_check_in, mood_level: 8, created_at: Time.zone.now.beginning_of_month + 25.days, user: signed_in_user)
    same_day = Time.zone.now.beginning_of_month + 9.days
    create(:mood_check_in, mood_level: 3, created_at: same_day + 2.hours, user: signed_in_user)
    create(:mood_check_in, mood_level: 9, created_at: same_day + 5.hours, user: signed_in_user)
  end

  it "exports daily labels and values on the chart canvas" do
    get checkins_path
    expect(response).to have_http_status(:success)

    doc = Nokogiri::HTML(response.body)
    canvas = doc.at_css('canvas[data-controller="checkins-chart"]')
    expect(canvas).to be_present

    labels = JSON.parse(canvas["data-checkins-chart-labels-value"])
    values = JSON.parse(canvas["data-checkins-chart-values-value"])

    expect(labels.first).to eq("1")

    days_in_month = Time.zone.now.end_of_month.day
    expect(values.length).to eq(days_in_month)

    expect(values[9]).to eq(9)
  end
end

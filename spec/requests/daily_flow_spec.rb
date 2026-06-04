require "rails_helper"

RSpec.describe "DailyFlow", type: :request do
  before { sign_in_test_user }
  it "redirects start to check_in" do
    get daily_flow_start_path
    expect(response).to redirect_to(daily_flow_check_in_path)
  end

  it "gets check_in page" do
    get daily_flow_check_in_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Daily Check-In")
    expect(response.body).to include("mood_check_in[mood_level]")
    expect(response.body).to include("mood_check_in[notes]")
  end

  it "saves check_in and redirects to affirmation" do
    expect {
      post daily_flow_save_check_in_path, params: { mood_check_in: { mood_level: 8, notes: "Feeling great today!" } }
    }.to change(MoodCheckIn, :count).by(1)

    expect(response).to redirect_to(daily_flow_affirmation_path)
    mood = MoodCheckIn.last
    expect(mood.mood_level).to eq(8)
    expect(mood.notes).to eq("Feeling great today!")
  end

  it "renders check_in on invalid mood data" do
    expect {
      post daily_flow_save_check_in_path, params: { mood_check_in: { mood_level: nil } }
    }.not_to change(MoodCheckIn, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "gets affirmation page" do
    get daily_flow_affirmation_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Your Daily Affirmation")
  end

  it "gets gratitude page" do
    get daily_flow_gratitude_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Record Your Gratitudes")
    expect(response.body).to include("gratitude[contents][]")
  end

  it "saves gratitudes and redirects to reflection" do
    expect {
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: [ "I am grateful for sunshine", "I am grateful for health", "I am grateful for family" ] }
      }
    }.to change(Gratitude, :count).by(3)

    expect(response).to redirect_to(daily_flow_reflection_path)
  end

  it "handles empty gratitudes gracefully" do
    expect {
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: [ "I am grateful for coffee", "", "I am grateful for music" ] }
      }
    }.to change(Gratitude, :count).by(2)

    expect(response).to redirect_to(daily_flow_reflection_path)
  end

  it "renders gratitude on invalid data" do
    expect {
      post daily_flow_save_gratitude_path, params: { gratitude: { contents: "not an array" } }
    }.not_to change(Gratitude, :count)

    expect(response).to have_http_status(:unprocessable_content)
  end

  it "gets reflection page" do
    Gratitude.create!(content: "Test gratitude 1")
    Gratitude.create!(content: "Test gratitude 2")

    get daily_flow_reflection_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Reflect & Reinforce")
  end

  it "saves reflection and redirects to completion" do
    post daily_flow_save_reflection_path, params: { reflection: { content: "Test reflection" } }
    expect(response).to redirect_to(daily_flow_completion_path)
  end

  it "gets completion page" do
    get daily_flow_completion_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Well Done!")
  end

  it "shows today's data on completion page" do
    MoodCheckIn.create!(mood_level: 8, notes: "Good day")
    Gratitude.create!(content: "Test gratitude")

    get daily_flow_completion_path
    expect(response).to have_http_status(:success)
  end
end

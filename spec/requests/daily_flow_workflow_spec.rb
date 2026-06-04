require "rails_helper"

RSpec.describe "DailyFlowWorkflow", type: :request do
  before { sign_in_test_user }
  it "completes daily workflow from start to finish" do
    get daily_flow_start_path
    expect(response).to redirect_to(daily_flow_check_in_path)
    follow_redirect!
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Daily Check-In")

    expect {
      post daily_flow_save_check_in_path, params: {
        mood_check_in: { mood_level: 8, notes: "Feeling great today!" }
      }
    }.to change(MoodCheckIn, :count).by(1)
    expect(response).to redirect_to(daily_flow_affirmation_path)
    follow_redirect!
    expect(response.body).to include("Your Daily Affirmation")

    get daily_flow_gratitude_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Record Your Gratitudes")

    expect {
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: [ "I am grateful for sunshine", "I am grateful for health", "I am grateful for family" ] }
      }
    }.to change(Gratitude, :count).by(3)
    expect(response).to redirect_to(daily_flow_reflection_path)
    follow_redirect!
    expect(response.body).to include("Reflect & Reinforce")

    post daily_flow_save_reflection_path, params: { reflection: { content: "Workflow reflection" } }
    expect(response).to redirect_to(daily_flow_completion_path)
    follow_redirect!
    expect(response.body).to include("Well Done!")

    mood = MoodCheckIn.last
    expect(mood.mood_level).to eq(8)
    expect(mood.notes).to eq("Feeling great today!")

    gratitudes = Gratitude.last(3)
    expect(gratitudes.count).to eq(3)
    expect(gratitudes[0].content).to eq("I am grateful for sunshine")
  end

  it "handles navigation between steps" do
    get daily_flow_check_in_path
    expect(response).to have_http_status(:success)

    post daily_flow_save_check_in_path, params: { mood_check_in: { mood_level: 7 } }
    expect(response).to redirect_to(daily_flow_affirmation_path)

    get daily_flow_gratitude_path
    expect(response).to have_http_status(:success)

    get daily_flow_affirmation_path
    expect(response).to have_http_status(:success)

    get daily_flow_gratitude_path
    expect(response).to have_http_status(:success)
  end

  it "shows today's data on completion" do
    MoodCheckIn.create!(mood_level: 9, notes: "Excellent day")
    Gratitude.create!(content: "Test gratitude 1")
    Gratitude.create!(content: "Test gratitude 2")

    get daily_flow_completion_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Well Done!")
  end

  it "handles invalid mood data" do
    get daily_flow_check_in_path
    expect(response).to have_http_status(:success)

    expect {
      post daily_flow_save_check_in_path, params: { mood_check_in: { mood_level: nil } }
    }.not_to change(MoodCheckIn, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Daily Check-In")
  end

  it "handles empty gratitudes" do
    get daily_flow_gratitude_path
    expect(response).to have_http_status(:success)

    expect {
      post daily_flow_save_gratitude_path, params: { gratitude: { contents: [ "", "", "" ] } }
    }.not_to change(Gratitude, :count)

    expect(response).to redirect_to(daily_flow_reflection_path)
  end

  it "can be accessed via breadcrumb route" do
    get daily_flow_path
    expect(response).to redirect_to(daily_flow_check_in_path)
  end
end

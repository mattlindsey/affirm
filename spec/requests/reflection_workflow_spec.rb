require "rails_helper"

RSpec.describe "ReflectionWorkflow", type: :request do
  it "saves a reflection and shows it on completion" do
    post daily_flow_save_check_in_path, params: { mood_check_in: { mood_level: 6 } }
    expect(response).to redirect_to(daily_flow_affirmation_path)
    follow_redirect!

    post daily_flow_save_gratitude_path, params: { gratitude: { contents: [ "g1", "g2", "g3" ] } }
    expect(response).to redirect_to(daily_flow_reflection_path)
    follow_redirect!

    expect {
      post daily_flow_save_reflection_path, params: { reflection: { content: "My reflection" } }
    }.to change(Reflection, :count).by(1)

    expect(response).to redirect_to(daily_flow_completion_path)
    follow_redirect!
    expect(response).to have_http_status(:success)

    expect(response.body).to include("Your Reflections")
    expect(response.body).to include("My reflection")
  end
end

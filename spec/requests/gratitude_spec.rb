require "rails_helper"

RSpec.describe "Gratitude", type: :request do
  let!(:gratitude) { create(:gratitude) }

  it "gets index" do
    get gratitude_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Gratitudes")
    expect(response.body).to include("📝 Create Today&#39;s Gratitudes")
    expect(response.body).to include("🎲 Get Random Gratitude")
  end

  it "gets random gratitude" do
    get gratitude_random_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Random Gratitude")
  end

  it "gets prompt page" do
    get gratitude_prompt_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Random Gratitude Prompt")
    expect(response.body).to include("← Back to Gratitude")
  end
end

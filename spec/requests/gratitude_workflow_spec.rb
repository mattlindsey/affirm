require "rails_helper"

RSpec.describe "GratitudeWorkflow", type: :request do
  let(:valid_gratitudes) do
    [
      "I am grateful for the beautiful weather today",
      "I am grateful for my supportive family",
      "I am grateful for good health and energy"
    ]
  end

  it "completes gratitude creation workflow via daily flow" do
    get gratitude_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Gratitudes")

    get daily_flow_start_path
    follow_redirect!
    expect(response).to have_http_status(:success)

    get daily_flow_gratitude_path
    expect(response).to have_http_status(:success)
    expect(response.body).to include("Record Your Gratitudes")
    expect(response.body).to include("gratitude[contents][]")

    expect {
      post daily_flow_save_gratitude_path, params: { gratitude: { contents: valid_gratitudes } }
    }.to change(Gratitude, :count).by(3)

    expect(response).to redirect_to(daily_flow_reflection_path)
    follow_redirect!
    expect(response).to have_http_status(:success)

    get gratitude_path
    valid_gratitudes.each { |content| expect(response.body).to include(content) }
  end

  it "creates gratitudes with partial content" do
    get daily_flow_gratitude_path
    expect(response).to have_http_status(:success)

    expect {
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: [ "I am grateful for coffee", "", "I am grateful for music" ] }
      }
    }.to change(Gratitude, :count).by(2)

    expect(response).to redirect_to(daily_flow_reflection_path)
    follow_redirect!
    expect(response).to have_http_status(:success)

    get gratitude_path
    expect(response.body).to include("I am grateful for coffee")
    expect(response.body).to include("I am grateful for music")
  end

  it "handles whitespace in gratitude content" do
    get daily_flow_gratitude_path

    expect {
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: [ "  I am grateful for space  ", "  Another gratitude  ", "  Third gratitude  " ] }
      }
    }.to change(Gratitude, :count).by(3)

    expect(response).to redirect_to(daily_flow_reflection_path)
    follow_redirect!

    get gratitude_path
    expect(response.body).to include("I am grateful for space")
    expect(response.body).to include("Another gratitude")
    expect(response.body).to include("Third gratitude")
  end

  it "handles no content" do
    get daily_flow_gratitude_path

    expect {
      post daily_flow_save_gratitude_path, params: { gratitude: { contents: [ "", "", "" ] } }
    }.not_to change(Gratitude, :count)

    expect(response).to redirect_to(daily_flow_reflection_path)
    follow_redirect!
    expect(response).to have_http_status(:success)
  end

  it "handles malformed parameters" do
    get daily_flow_gratitude_path

    expect {
      post daily_flow_save_gratitude_path, params: { gratitude: { contents: "not an array" } }
    }.not_to change(Gratitude, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Record Your Gratitudes")
  end

  it "handles missing parameters" do
    get daily_flow_gratitude_path

    expect {
      post daily_flow_save_gratitude_path, params: {}
    }.not_to change(Gratitude, :count)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Record Your Gratitudes")
  end

  it "navigates between gratitude pages" do
    get gratitude_path
    expect(response).to have_http_status(:success)

    get daily_flow_start_path
    follow_redirect!
    expect(response).to have_http_status(:success)

    get gratitude_random_path
    expect(response).to have_http_status(:success)

    get gratitude_path
    expect(response).to have_http_status(:success)
  end

  it "preserves existing gratitudes when creating new ones" do
    Gratitude.create!(content: "I am grateful for existing content")

    get gratitude_path
    expect(response.body).to include("I am grateful for existing content")

    get daily_flow_gratitude_path

    expect {
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: [ "New gratitude 1", "", "New gratitude 2" ] }
      }
    }.to change(Gratitude, :count).by(2)

    expect(response).to redirect_to(daily_flow_reflection_path)
    follow_redirect!

    get gratitude_path
    expect(response.body).to include("I am grateful for existing content")
    expect(response.body).to include("New gratitude 1")
    expect(response.body).to include("New gratitude 2")
  end
end

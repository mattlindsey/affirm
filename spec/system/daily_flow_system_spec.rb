require "rails_helper"

RSpec.describe "DailyFlowSystem", type: :system do
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ])
    sign_in_as_test_user
  end

  it "completes daily workflow from home page" do
    visit root_path
    expect(page).to have_text("Welcome")

    click_on "Start Daily Workflow"

    expect(page).to have_text("Daily Check-In")
    expect(page).to have_text("How are you feeling today?")

    find("#mood-slider").set(8)
    fill_in "mood_check_in[notes]", with: "Feeling productive today!"
    click_on "Next: Affirmation"

    expect(page).to have_text("Your Daily Affirmation")
    click_on "Next: Gratitude"

    expect(page).to have_text("Record Your Gratitudes")
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("I am grateful for my health")
    textareas[1].set("I am grateful for my family")
    textareas[2].set("I am grateful for this opportunity")
    click_on "Next: Reflect"

    expect(page).to have_text("Reflect & Reinforce")
    expect(page).to have_text("I am grateful for my health")
    expect(page).to have_text("I am grateful for my family")
    expect(page).to have_text("I am grateful for this opportunity")
    fill_in "reflection[content]", with: "I will take a short walk to boost my energy"
    click_on "Complete Workflow"

    expect(page).to have_text("Well Done!")
    expect(page).to have_text("You've completed your daily workflow")
  end

  it "navigates with back buttons" do
    visit daily_flow_check_in_path
    find("#mood-slider").set(7)
    click_on "Next: Affirmation"

    expect(page).to have_text("Your Daily Affirmation")
    click_on "Next: Gratitude"

    expect(page).to have_text("Record Your Gratitudes")
    click_on "← Back"
    expect(page).to have_text("Your Daily Affirmation")
  end

  it "shows progress indicator" do
    visit daily_flow_check_in_path
    expect(page).to have_selector(".bg-blue-600", text: "1")
    expect(page).to have_selector(".text-blue-600", text: "Check-In")

    find("#mood-slider").set(5)
    click_on "Next: Affirmation"
    expect(page).to have_text("Your Daily Affirmation")
  end

  it "supports mood slider interaction" do
    visit daily_flow_check_in_path
    expect(page).to have_selector("#mood-emoji")
    expect(page).to have_selector("#mood-description")

    find("#mood-slider").set(10)
    expect(page).to have_selector("#mood-emoji")
  end

  it "displays gratitude prompt" do
    visit daily_flow_gratitude_path
    expect(page).to have_selector(".bg-gradient-to-r.from-purple-50.to-pink-50")
    expect(page).to have_text("Prompt:")
  end

  it "exits workflow from check-in page" do
    visit daily_flow_check_in_path
    click_on "← Exit Workflow"
    expect(page).to have_text("Welcome")
  end

  it "shows completion summary" do
    MoodCheckIn.create!(mood_level: 8, notes: "Good day")
    Gratitude.create!(content: "Test gratitude")

    visit daily_flow_completion_path
    expect(page).to have_text("Well Done!")
    expect(page).to have_text("You've completed your daily workflow")
  end

  it "is accessible from navigation" do
    visit root_path
    within("nav") { click_on "Daily Workflow" }
    expect(page).to have_text("Daily Check-In")
  end
end

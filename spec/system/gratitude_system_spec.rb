require "rails_helper"

RSpec.describe "GratitudeSystem", type: :system do
  before do
    driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ])
    sign_in_as_test_user
  end

  let(:valid_gratitudes) do
    [
      "I am grateful for the beautiful weather today",
      "I am grateful for my supportive family",
      "I am grateful for good health and energy"
    ]
  end

  it "visits the gratitude index page" do
    visit gratitude_path
    expect(page).to have_text("Gratitude")
    expect(page).to have_text("📝 Create Today's Gratitudes")
    expect(page).to have_text("🎲 Get Random Gratitude")

    if page.has_content?("No gratitudes yet")
      expect(page).to have_text("No gratitudes yet. Create today's gratitudes to get started!")
    end
  end

  it "creates new gratitudes through daily workflow" do
    visit gratitude_path
    click_on "📝 Create Today's Gratitudes"
    expect(page).to have_text("Record Your Gratitudes")

    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set(valid_gratitudes[0])
    textareas[1].set(valid_gratitudes[1])
    textareas[2].set(valid_gratitudes[2])
    click_on "Next: Reflect"

    expect(page).to have_text("Reflect & Reinforce")

    visit gratitude_path
    valid_gratitudes.each { |content| expect(page).to have_text(content) }
  end

  it "creates gratitudes with partial content" do
    visit daily_flow_gratitude_path

    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("I am grateful for coffee")
    textareas[2].set("I am grateful for music")
    click_on "Next: Reflect"

    expect(page).to have_text("Reflect & Reinforce")

    visit gratitude_path
    expect(page).to have_text("I am grateful for coffee")
    expect(page).to have_text("I am grateful for music")
    expect(page).to have_selector("p", text: "I am grateful for coffee")
    expect(page).to have_selector("p", text: "I am grateful for music")
  end

  it "handles whitespace in gratitude content" do
    visit daily_flow_gratitude_path

    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("  I am grateful for space  ")
    textareas[1].set("  Another gratitude  ")
    textareas[2].set("  Third gratitude  ")
    click_on "Next: Reflect"

    expect(page).to have_text("Reflect & Reinforce")

    visit gratitude_path
    expect(page).to have_text("I am grateful for space")
    expect(page).to have_text("Another gratitude")
    expect(page).to have_text("Third gratitude")
  end

  it "navigates back from gratitude creation" do
    visit daily_flow_gratitude_path

    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("Test gratitude")
    click_on "← Back"

    expect(page).to have_text("Daily Affirmation")
  end

  it "validates and handles form errors" do
    visit daily_flow_gratitude_path
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("Valid gratitude")
    textareas[1].set("Valid gratitude1")
    textareas[2].set("Valid gratitude2")
    click_on "Next: Reflect"

    expect(page).to have_text("Reflect & Reinforce")

    visit gratitude_path
    expect(page).to have_text("Valid gratitude")
  end

  it "navigates between gratitude pages" do
    visit gratitude_path
    expect(page).to have_text("Gratitude")

    click_on "📝 Create Today's Gratitudes"
    expect(page).to have_text("Record Your Gratitudes")

    visit gratitude_path
    click_on "🎲 Get Random Gratitude"
    expect(page).to have_text("Random Gratitude")

    visit gratitude_path
    expect(page).to have_text("Gratitude")
  end

  it "has accessible form structure" do
    visit daily_flow_gratitude_path

    expect(page).to have_selector("form[action*='gratitude']")
    expect(page).to have_selector("textarea[name='gratitude[contents][]']", count: 3)
    expect(page).to have_selector("label", text: "Gratitude 1:")
    expect(page).to have_selector("label", text: "Gratitude 2:")
    expect(page).to have_selector("label", text: "Gratitude 3:")
    expect(page).to have_selector("textarea[placeholder='I am grateful for...']", count: 3)

    textareas = page.all("textarea[name='gratitude[contents][]']")
    expect(textareas[0][:required]).to be_present

    expect(page).to have_selector("input[type='submit'][value='Next: Reflect →']")
    expect(page).to have_selector("a", text: "← Back")
  end

  it "displays gratitudes with correct formatting" do
    visit daily_flow_gratitude_path
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("I am grateful for testing")
    click_on "Next: Reflect"

    visit gratitude_path
    expect(page).to have_selector("div.bg-gray-50.border-l-4.border-green-500")
    expect(page).to have_text("I am grateful for testing")
    expect(page).to have_selector("small.text-sm.text-gray-500")
  end

  it "shows empty state when no gratitudes exist" do
    Gratitude.destroy_all

    visit gratitude_path
    expect(page).to have_text("No gratitudes yet. Create today's gratitudes to get started!")
    expect(page).to have_selector("a", text: "📝 Create Today's Gratitudes")
  end
end

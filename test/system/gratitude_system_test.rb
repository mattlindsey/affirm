require "application_system_test_case"

class GratitudeSystemTest < ApplicationSystemTestCase
  def setup
    @valid_gratitudes = [
      "I am grateful for the beautiful weather today",
      "I am grateful for my supportive family",
      "I am grateful for good health and energy"
    ]
  end

  test "visiting the gratitude index page" do
    visit gratitude_path

    assert_text "Gratitude"
  assert_text "📝 Create Today's Gratitudes"
    assert_text "🎲 Get Random Gratitude"

    # Check if there are existing gratitudes or the empty state message
    if page.has_content?("No gratitudes yet")
      assert_text "No gratitudes yet. Create today's gratitudes to get started!"
    end
  end

  test "creating new gratitudes through daily workflow" do
    visit gratitude_path
    click_on "📝 Create Today's Gratitudes"

    # Should redirect to daily flow
    assert_text "Daily Check-In"

    # Navigate to gratitude step
    visit daily_flow_gratitude_path
    assert_text "Record Your Gratitudes"

    # Fill out the form using more specific selectors
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set(@valid_gratitudes[0])
    textareas[1].set(@valid_gratitudes[1])
    textareas[2].set(@valid_gratitudes[2])

    # Submit the form
    click_on "Next: Reflect"

    # Verify redirect to reflection
    assert_text "Reflect & Reinforce"

    # Verify gratitudes are displayed on gratitude index
    visit gratitude_path
    @valid_gratitudes.each do |content|
      assert_text content
    end
  end

  test "creating gratitudes with partial content" do
    visit daily_flow_gratitude_path

    # Fill only first and third fields using array indexing
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("I am grateful for coffee")
    textareas[2].set("I am grateful for music")
    # Leave second field empty

    click_on "Next: Reflect"

    assert_text "Reflect & Reinforce"

    # Verify gratitudes on index page
    visit gratitude_path
    assert_text "I am grateful for coffee"
    assert_text "I am grateful for music"

    # Verify we can see the gratitudes on the page
    assert_selector "p", text: "I am grateful for coffee"
    assert_selector "p", text: "I am grateful for music"
  end

  test "creating gratitudes with whitespace handling" do
    visit daily_flow_gratitude_path

    # Fill fields with extra whitespace using array indexing
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("  I am grateful for space  ")
    textareas[1].set("  Another gratitude  ")
    textareas[2].set("  Third gratitude  ")

    click_on "Next: Reflect"

    assert_text "Reflect & Reinforce"

    # Verify content was stripped on gratitude index
    visit gratitude_path
    assert_text "I am grateful for space"
    assert_text "Another gratitude"
    assert_text "Third gratitude"
  end

  test "navigating back from gratitude creation" do
    visit daily_flow_gratitude_path

    # Fill one field to make sure we have content
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("Test gratitude")

    # Click back to go to previous step
    click_on "← Back"

    # Should return to affirmation page
    assert_text "Daily Affirmation"
  end

  test "form validation and error handling" do
    visit daily_flow_gratitude_path

    # Try to submit with all empty fields
    click_on "Next: Reflect"

    # Should redirect to reflection (empty gratitudes are allowed)
    assert_text "Reflect & Reinforce"

    # Go back and fill at least one field
    visit daily_flow_gratitude_path
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("Valid gratitude")
    click_on "Next: Reflect"

    assert_text "Reflect & Reinforce"

    # Verify on gratitude index
    visit gratitude_path
    assert_text "Valid gratitude"
  end

  test "navigation between gratitude pages" do
    visit gratitude_path
    assert_text "Gratitude"

    # Go to daily flow
    click_on "📝 Create Today's Gratitudes"
    assert_text "Daily Check-In"

    # Go to random page
    visit gratitude_path
    click_on "🎲 Get Random Gratitude"
    assert_text "Random Gratitude"

    # Return to index
    visit gratitude_path
    assert_text "Gratitude"
  end

  test "gratitude form accessibility and UX" do
    visit daily_flow_gratitude_path

    # Check form structure
    assert_selector "form[action*='gratitude']"
    assert_selector "textarea[name='gratitude[contents][]']", count: 3

    # Check labels are properly associated
    assert_selector "label", text: "Gratitude 1:"
    assert_selector "label", text: "Gratitude 2:"
    assert_selector "label", text: "Gratitude 3:"

    # Check placeholder text
    assert_selector "textarea[placeholder='I am grateful for...']", count: 3

    # Check required field (first one should be required)
    textareas = page.all("textarea[name='gratitude[contents][]']")
    assert textareas[0][:required]

    # Check button states
    assert_selector "input[type='submit'][value='Next: Reflect →']"
    assert_selector "a", text: "← Back"
  end

  test "gratitude display formatting" do
    # Create some gratitudes first
    visit daily_flow_gratitude_path
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("I am grateful for testing")
    click_on "Next: Reflect"

    # Visit gratitude index to verify display format
    visit gratitude_path
    assert_selector "div.bg-gray-50.border-l-4.border-green-500"
    assert_text "I am grateful for testing"

    # Check if creation date is displayed
    assert_selector "small.text-sm.text-gray-500"
  end

  test "empty gratitude state handling" do
    # Start with no gratitudes
    Gratitude.destroy_all

    visit gratitude_path

    # Should show empty state message
    assert_text "No gratitudes yet. Create today's gratitudes to get started!"

  # Create button should still be available
  assert_selector "a", text: "📝 Create Today's Gratitudes"
  end
end

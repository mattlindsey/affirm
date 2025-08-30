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
    assert_text "📝 Create todays gratitudes"
    assert_text "🎲 Get Random Gratitude"

    # Check if there are existing gratitudes or the empty state message
    if page.has_content?("No gratitudes yet")
      assert_text "No gratitudes yet. Create today's gratitudes to get started!"
    end
  end

  test "creating new gratitudes through the form" do
    visit gratitude_path
    click_on "📝 Create todays gratitudes"

    assert_text "Create Today's Gratitudes"
    assert_text "Take a moment to reflect on what you're grateful for today"

    # Fill out the form using more specific selectors
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set(@valid_gratitudes[0])
    textareas[1].set(@valid_gratitudes[1])
    textareas[2].set(@valid_gratitudes[2])

    # Submit the form
    click_on "Create Gratitudes"

    # Verify success message and redirect
    assert_text "Today's gratitudes created successfully!"
    assert_text "Gratitude"

    # Verify gratitudes are displayed
    @valid_gratitudes.each do |content|
      assert_text content
    end
  end

  test "creating gratitudes with partial content" do
    visit create_gratitude_path

    # Fill only first and third fields using array indexing
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("I am grateful for coffee")
    textareas[2].set("I am grateful for music")
    # Leave second field empty

    click_on "Create Gratitudes"

    assert_text "Today's gratitudes created successfully!"
    assert_text "I am grateful for coffee"
    assert_text "I am grateful for music"

    # Verify the specific gratitudes we created are present
    assert_text "I am grateful for coffee"
    assert_text "I am grateful for music"

    # Verify we can see the gratitudes on the page
    assert_selector "p", text: "I am grateful for coffee"
    assert_selector "p", text: "I am grateful for music"
  end

  test "creating gratitudes with whitespace handling" do
    visit create_gratitude_path

    # Fill fields with extra whitespace using array indexing
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("  I am grateful for space  ")
    textareas[1].set("  Another gratitude  ")
    textareas[2].set("  Third gratitude  ")

    click_on "Create Gratitudes"

    assert_text "Today's gratitudes created successfully!"

    # Verify content was stripped
    assert_text "I am grateful for space"
    assert_text "Another gratitude"
    assert_text "Third gratitude"
  end

  test "canceling gratitude creation" do
    visit create_gratitude_path

    # Fill one field to make sure we have content
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("Test gratitude")

    # Click cancel instead of submit
    click_on "Cancel"

    # Should return to index page
    assert_text "Gratitude"
    assert_no_text "Create Today's Gratitudes"

    # No gratitudes should have been created
    assert_no_text "Test gratitude"
  end

  test "form validation and error handling" do
    visit create_gratitude_path

    # Try to submit with all empty fields
    click_on "Create Gratitudes"

    # Should still be on create page
    assert_text "Create Today's Gratitudes"

    # Fill at least one field and submit
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("Valid gratitude")
    click_on "Create Gratitudes"

    assert_text "Today's gratitudes created successfully!"
    assert_text "Valid gratitude"
  end

  test "navigation between gratitude pages" do
    visit gratitude_path
    assert_text "Gratitude"

    # Go to create page
    click_on "📝 Create todays gratitudes"
    assert_text "Create Today's Gratitudes"

    # Go back to index
    click_on "Cancel"
    assert_text "Gratitude"

    # Go to random page
    click_on "🎲 Get Random Gratitude"
    assert_text "Random Gratitude"

    # Return to index (assuming there's a back link or we can navigate)
    visit gratitude_path
    assert_text "Gratitude"
  end

  test "gratitude form accessibility and UX" do
    visit create_gratitude_path

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
    assert_selector "input[type='submit'][value='Create Gratitudes']"
    assert_selector "a", text: "Cancel"
  end

  test "gratitude display formatting" do
    # Create some gratitudes first
    visit create_gratitude_path
    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("I am grateful for testing")
    click_on "Create Gratitudes"

    # Verify the display format
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
    assert_selector "a", text: "📝 Create todays gratitudes"
  end
end

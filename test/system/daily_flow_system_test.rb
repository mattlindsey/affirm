require "application_system_test_case"

class DailyFlowSystemTest < ApplicationSystemTestCase
  test "complete daily workflow from home page" do
    visit root_path
    assert_text "Welcome"

    # Start daily workflow
    click_on "Start Daily Workflow"

    # Step 1: Check-in
    assert_text "Daily Check-In"
    assert_text "How are you feeling today?"

    # Interact with mood slider
    slider = find("#mood-slider")
    slider.set(8)

    # Add optional notes
    fill_in "mood_check_in[notes]", with: "Feeling productive today!"

    click_on "Next: Affirmation"

    # Step 2: Affirmation
    assert_text "Your Daily Affirmation"

    click_on "Next: Gratitude"

    # Step 3: Gratitude
    assert_text "Record Your Gratitudes"

    textareas = page.all("textarea[name='gratitude[contents][]']")
    textareas[0].set("I am grateful for my health")
    textareas[1].set("I am grateful for my family")
    textareas[2].set("I am grateful for this opportunity")

    click_on "Next: Reflect"

    # Step 4: Reflection
    assert_text "Reflect & Reinforce"
    assert_text "I am grateful for my health"
    assert_text "I am grateful for my family"
    assert_text "I am grateful for this opportunity"

  # Fill the required reflection field
  fill_in "reflection[content]", with: "I will take a short walk to boost my energy"

  click_on "Complete Workflow"

    # Step 5: Completion
    assert_text "Well Done!"
    assert_text "You've completed your daily workflow"
  end

  test "daily workflow navigation with back buttons" do
    visit daily_flow_check_in_path

    # Fill check-in
    slider = find("#mood-slider")
    slider.set(7)
    click_on "Next: Affirmation"

    assert_text "Your Daily Affirmation"
    click_on "Next: Gratitude"

    assert_text "Record Your Gratitudes"

    # Go back to affirmation
    click_on "← Back"
    assert_text "Your Daily Affirmation"
  end

  test "daily workflow progress indicator" do
    visit daily_flow_check_in_path

    # Check progress indicator shows current step
    assert_selector ".bg-blue-600", text: "1"
    assert_selector ".text-blue-600", text: "Check-In"

    # Submit and move to next step
    slider = find("#mood-slider")
    slider.set(5)
    click_on "Next: Affirmation"

    # Progress should update
    assert_text "Your Daily Affirmation"
  end

  test "daily workflow mood slider interaction" do
    visit daily_flow_check_in_path

    # Check initial mood display
    assert_selector "#mood-emoji"
    assert_selector "#mood-description"

    # Interact with slider
    slider = find("#mood-slider")
    slider.set(10)

    # Mood display should update (via JavaScript)
    assert_selector "#mood-emoji"
  end

  test "daily workflow gratitude prompt display" do
    visit daily_flow_gratitude_path

    # Should show a random prompt
    assert_selector ".bg-gradient-to-r.from-purple-50.to-pink-50"
    assert_text "Prompt:"
  end

  test "daily workflow exit option" do
    visit daily_flow_check_in_path

    click_on "← Exit Workflow"

    # Should return to home page
    assert_text "Welcome"
  end

  test "daily workflow completion shows summary" do
    # Create some data first
    MoodCheckIn.create!(mood_level: 8, notes: "Good day")
    Gratitude.create!(content: "Test gratitude")

    visit daily_flow_completion_path

    assert_text "Well Done!"
    assert_text "You've completed your daily workflow"
  end

  test "daily workflow accessible from navigation" do
    visit root_path

    # Check navigation header
    within("nav") do
      click_on "Daily Workflow"
    end

    assert_text "Daily Check-In"
  end
end

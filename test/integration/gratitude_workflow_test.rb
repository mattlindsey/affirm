require "test_helper"

class GratitudeWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    @valid_gratitudes = [
      "I am grateful for the beautiful weather today",
      "I am grateful for my supportive family",
      "I am grateful for good health and energy"
    ]
  end

  test "complete gratitude creation workflow via daily flow" do
    # Step 1: Visit the gratitude index page
    get gratitude_path
    assert_response :success
    assert_select "h1", "Gratitudes"

    # Step 2: Start daily flow and navigate to gratitude step
    get daily_flow_start_path
    follow_redirect!
    assert_response :success

    # Skip to gratitude step
    get daily_flow_gratitude_path
    assert_response :success
    assert_select "h1", "Record Your Gratitudes"
    assert_select "form[action='#{daily_flow_save_gratitude_path}'][method='post']"
    assert_select "textarea[name='gratitude[contents][]']", count: 3

    # Step 3: Submit the form with valid data
    assert_difference "Gratitude.count", 3 do
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: @valid_gratitudes }
      }
    end

    # Step 4: Verify redirect to reflection
    assert_redirected_to daily_flow_reflection_path
    follow_redirect!
    assert_response :success

    # Step 5: Verify gratitudes are displayed on gratitude index page
    get gratitude_path
    assert_response :success
    @valid_gratitudes.each do |content|
      assert_select "p", content
    end
  end

  test "gratitude creation with partial content" do
    partial_gratitudes = [
      "I am grateful for coffee",
      "",  # Empty
      "I am grateful for music"
    ]

    get daily_flow_gratitude_path
    assert_response :success

    assert_difference "Gratitude.count", 2 do
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: partial_gratitudes }
      }
    end

    assert_redirected_to daily_flow_reflection_path
    follow_redirect!
    assert_response :success

    # Verify only non-empty gratitudes were created on gratitude index
    get gratitude_path
    assert_select "p", "I am grateful for coffee"
    assert_select "p", "I am grateful for music"
  end

  test "gratitude creation with whitespace handling" do
    whitespace_gratitudes = [
      "  I am grateful for space  ",
      "  Another gratitude  ",
      "  Third gratitude  "
    ]

    get daily_flow_gratitude_path
    assert_response :success

    assert_difference "Gratitude.count", 3 do
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: whitespace_gratitudes }
      }
    end

    assert_redirected_to daily_flow_reflection_path
    follow_redirect!
    assert_response :success

    # Verify content was stripped on gratitude index
    get gratitude_path
    assert_select "p", "I am grateful for space"
    assert_select "p", "Another gratitude"
    assert_select "p", "Third gratitude"
  end

  test "gratitude creation with no content" do
    get daily_flow_gratitude_path
    assert_response :success

    assert_no_difference "Gratitude.count" do
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: [ "", "", "" ] }
      }
    end

    assert_redirected_to daily_flow_reflection_path
    follow_redirect!
    assert_response :success
  end

  test "gratitude creation form validation" do
    get daily_flow_gratitude_path
    assert_response :success

    # Test with malformed parameters
    assert_no_difference "Gratitude.count" do
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: "not an array" }
      }
    end

    assert_response :unprocessable_content
    assert_select "h1", "Record Your Gratitudes"
  end

  test "gratitude creation with missing parameters" do
    get daily_flow_gratitude_path
    assert_response :success

    assert_no_difference "Gratitude.count" do
      post daily_flow_save_gratitude_path, params: {}
    end

    assert_response :unprocessable_content
    assert_select "h1", "Record Your Gratitudes"
  end

  test "navigation between gratitude pages" do
    # Start at index
    get gratitude_path
    assert_response :success

    # Go to daily flow
    get daily_flow_start_path
    follow_redirect!
    assert_response :success

    # Go to random page
    get gratitude_random_path
    assert_response :success

    # Return to index
    get gratitude_path
    assert_response :success
  end

  test "gratitude creation preserves existing gratitudes" do
    # Create initial gratitudes
    existing_gratitude = Gratitude.create!(content: "I am grateful for existing content")

    get gratitude_path
    assert_response :success
    assert_select "p", "I am grateful for existing content"

    # Create new gratitudes via daily flow
    get daily_flow_gratitude_path
    assert_response :success

    assert_difference "Gratitude.count", 2 do
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: [ "New gratitude 1", "", "New gratitude 2" ] }
      }
    end

    assert_redirected_to daily_flow_reflection_path
    follow_redirect!
    assert_response :success

    # Verify both old and new gratitudes are present on index
    get gratitude_path
    assert_select "p", "I am grateful for existing content"
    assert_select "p", "New gratitude 1"
    assert_select "p", "New gratitude 2"
  end
end

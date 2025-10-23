require "test_helper"

class GratitudeWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    @valid_gratitudes = [
      "I am grateful for the beautiful weather today",
      "I am grateful for my supportive family",
      "I am grateful for good health and energy"
    ]
  end

  test "complete gratitude creation workflow" do
    # Step 1: Visit the gratitude index page
  get gratitude_path
  assert_response :success
  assert_select "h1", "Gratitudes"

    # Step 2: Click on create gratitudes link
    get create_gratitude_path
    assert_response :success
    assert_select "h1", "Create Today's Gratitudes"
    assert_select "form[action='#{store_gratitude_path}'][method='post']"
    assert_select "textarea[name='gratitude[contents][]']", count: 3

    # Step 3: Submit the form with valid data
    assert_difference "Gratitude.count", 3 do
      post store_gratitude_path, params: {
        gratitude: { contents: @valid_gratitudes }
      }
    end

    # Step 4: Verify redirect and flash message
    assert_redirected_to gratitude_path
    follow_redirect!
    assert_response :success
    assert_select ".bg-green-100", "Today's gratitudes created successfully!"

    # Step 5: Verify gratitudes are displayed on index page
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

    get create_gratitude_path
    assert_response :success

    assert_difference "Gratitude.count", 2 do
      post store_gratitude_path, params: {
        gratitude: { contents: partial_gratitudes }
      }
    end

    assert_redirected_to gratitude_path
    follow_redirect!
    assert_response :success
    assert_select ".bg-green-100", "Today's gratitudes created successfully!"

    # Verify only non-empty gratitudes were created
    assert_select "p", "I am grateful for coffee"
    assert_select "p", "I am grateful for music"
  end

  test "gratitude creation with whitespace handling" do
    whitespace_gratitudes = [
      "  I am grateful for space  ",
      "  Another gratitude  ",
      "  Third gratitude  "
    ]

    get create_gratitude_path
    assert_response :success

    assert_difference "Gratitude.count", 3 do
      post store_gratitude_path, params: {
        gratitude: { contents: whitespace_gratitudes }
      }
    end

    assert_redirected_to gratitude_path
    follow_redirect!
    assert_response :success

    # Verify content was stripped
    assert_select "p", "I am grateful for space"
    assert_select "p", "Another gratitude"
    assert_select "p", "Third gratitude"
  end

  test "gratitude creation with no content" do
    get create_gratitude_path
    assert_response :success

    assert_no_difference "Gratitude.count" do
      post store_gratitude_path, params: {
        gratitude: { contents: [ "", "", "" ] }
      }
    end

    assert_redirected_to gratitude_path
    follow_redirect!
    assert_response :success
    assert_select ".bg-green-100", "Today's gratitudes created successfully!"
  end

  test "gratitude creation form validation" do
    get create_gratitude_path
    assert_response :success

    # Test with malformed parameters
    assert_no_difference "Gratitude.count" do
      post store_gratitude_path, params: {
        gratitude: { contents: "not an array" }
      }
    end

    assert_response :unprocessable_content
    assert_select "h1", "Create Today's Gratitudes"
  end

  test "gratitude creation with missing parameters" do
    get create_gratitude_path
    assert_response :success

    assert_no_difference "Gratitude.count" do
      post store_gratitude_path, params: {}
    end

    assert_response :unprocessable_content
    assert_select "h1", "Create Today's Gratitudes"
  end

  test "navigation between gratitude pages" do
    # Start at index
    get gratitude_path
    assert_response :success

    # Go to create page
    get create_gratitude_path
    assert_response :success

    # Go back to index
    get gratitude_path
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

    # Create new gratitudes
    get create_gratitude_path
    assert_response :success

    assert_difference "Gratitude.count", 2 do
      post store_gratitude_path, params: {
        gratitude: { contents: [ "New gratitude 1", "", "New gratitude 2" ] }
      }
    end

    assert_redirected_to gratitude_path
    follow_redirect!
    assert_response :success

    # Verify both old and new gratitudes are present
    assert_select "p", "I am grateful for existing content"
    assert_select "p", "New gratitude 1"
    assert_select "p", "New gratitude 2"
  end
end

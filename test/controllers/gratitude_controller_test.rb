require "test_helper"

class GratitudeControllerTest < ActionDispatch::IntegrationTest
  def setup
    @gratitude = gratitudes(:one)
  end

  test "should get index" do
    get gratitude_path
    assert_response :success
    assert_select "h1", "Gratitude"
    assert_select "a", "📝 Create todays gratitudes"
    assert_select "a", "🎲 Get Random Gratitude"
    assert_select "a", "🎯 Random Prompt"
  end

  test "should get random gratitude" do
    get gratitude_random_path
    assert_response :success
    assert_select "h1", "Random Gratitude"
  end

  test "should get prompt page" do
    get gratitude_prompt_path
    assert_response :success
    assert_select "h1", "Random Gratitude Prompt"
    assert_select "form[action='#{store_gratitude_path}'][method='post']"
    assert_select "textarea[name='gratitude[contents][]']"
    assert_select "input[type='submit'][value='Save Response']"
    assert_select "a[href='#{gratitude_path}']", "← Back to Gratitude"
  end

  test "should get create page" do
    get create_gratitude_path
    assert_response :success
    assert_select "h1", "Create Today's Gratitudes"
    assert_select "form[action='#{store_gratitude_path}'][method='post']"
    assert_select "textarea[name='gratitude[contents][]']", count: 3
    assert_select "input[type='submit'][value='Create Gratitudes']"
    assert_select "a[href='#{gratitude_path}']", "Cancel"
  end

  test "should create multiple gratitudes successfully" do
    assert_difference "Gratitude.count", 3 do
      post store_gratitude_path, params: {
        gratitude: {
          contents: [
            "I am grateful for the sunshine",
            "I am grateful for good health",
            "I am grateful for my family"
          ]
        }
      }
    end

    assert_redirected_to gratitude_path
    assert_equal "Today's gratitudes created successfully!", flash[:notice]
  end

  test "should create gratitudes with mixed content" do
    assert_difference "Gratitude.count", 2 do
      post store_gratitude_path, params: {
        gratitude: {
          contents: [
            "I am grateful for coffee",
            "",  # Empty content should be skipped
            "I am grateful for music"
          ]
        }
      }
    end

    assert_redirected_to gratitude_path
    assert_equal "Today's gratitudes created successfully!", flash[:notice]
  end

  test "should handle single gratitude creation" do
    assert_difference "Gratitude.count", 1 do
      post store_gratitude_path, params: {
        gratitude: {
          contents: [
            "I am grateful for this moment",
            "",
            ""
          ]
        }
      }
    end

    assert_redirected_to gratitude_path
    assert_equal "Today's gratitudes created successfully!", flash[:notice]
  end

  test "should handle all empty content gracefully" do
    assert_no_difference "Gratitude.count" do
      post store_gratitude_path, params: {
        gratitude: {
          contents: [ "", "", "" ]
        }
      }
    end

    assert_redirected_to gratitude_path
    assert_equal "Today's gratitudes created successfully!", flash[:notice]
  end

  test "should handle nil content gracefully" do
    assert_no_difference "Gratitude.count" do
      post store_gratitude_path, params: {
        gratitude: {
          contents: [ nil, nil, nil ]
        }
      }
    end

    assert_redirected_to gratitude_path
    assert_equal "Today's gratitudes created successfully!", flash[:notice]
  end

  test "should strip whitespace from content" do
    post store_gratitude_path, params: {
      gratitude: {
        contents: [
          "  I am grateful for space  ",
          "  Another gratitude  ",
          "  Third gratitude  "
        ]
      }
    }

    assert_redirected_to gratitude_path
    assert_equal "Today's gratitudes created successfully!", flash[:notice]

    # Verify content was stripped - check the first gratitude created
    first_gratitude = Gratitude.order(:created_at).last(3).first
    assert_equal "I am grateful for space", first_gratitude.content
  end

  test "should handle malformed parameters gracefully" do
    assert_no_difference "Gratitude.count" do
      post store_gratitude_path, params: {
        gratitude: { contents: "not an array" }
      }
    end

    assert_response :unprocessable_content
  end

  test "should handle missing gratitude parameter" do
    assert_no_difference "Gratitude.count" do
      post store_gratitude_path, params: {}
    end

    assert_response :unprocessable_content
  end
end

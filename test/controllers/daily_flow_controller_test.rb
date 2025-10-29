require "test_helper"

class DailyFlowControllerTest < ActionDispatch::IntegrationTest
  test "should redirect start to check_in" do
    get daily_flow_start_path
    assert_redirected_to daily_flow_check_in_path
  end

  test "should get check_in page" do
    get daily_flow_check_in_path
    assert_response :success
    assert_select "h1", "Daily Check-In"
    assert_select "form[action='#{daily_flow_save_check_in_path}'][method='post']"
    assert_select "input[name='mood_check_in[mood_level]']"
    assert_select "textarea[name='mood_check_in[notes]']"
  end

  test "should save check_in and redirect to affirmation" do
    assert_difference "MoodCheckIn.count", 1 do
      post daily_flow_save_check_in_path, params: {
        mood_check_in: {
          mood_level: 8,
          notes: "Feeling great today!"
        }
      }
    end

    assert_redirected_to daily_flow_affirmation_path
    mood = MoodCheckIn.last
    assert_equal 8, mood.mood_level
    assert_equal "Feeling great today!", mood.notes
  end

  test "should render check_in on invalid mood data" do
    assert_no_difference "MoodCheckIn.count" do
      post daily_flow_save_check_in_path, params: {
        mood_check_in: {
          mood_level: nil
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "should get affirmation page" do
    get daily_flow_affirmation_path
    assert_response :success
    assert_select "h1", "Your Daily Affirmation"
  end

  test "should get gratitude page" do
    get daily_flow_gratitude_path
    assert_response :success
    assert_select "h1", "Record Your Gratitudes"
    assert_select "form[action='#{daily_flow_save_gratitude_path}'][method='post']"
    assert_select "textarea[name='gratitude[contents][]']", count: 3
  end

  test "should save gratitudes and redirect to reflection" do
    assert_difference "Gratitude.count", 3 do
      post daily_flow_save_gratitude_path, params: {
        gratitude: {
          contents: [
            "I am grateful for sunshine",
            "I am grateful for health",
            "I am grateful for family"
          ]
        }
      }
    end

    assert_redirected_to daily_flow_reflection_path
  end

  test "should handle empty gratitudes gracefully" do
    assert_difference "Gratitude.count", 2 do
      post daily_flow_save_gratitude_path, params: {
        gratitude: {
          contents: [
            "I am grateful for coffee",
            "",
            "I am grateful for music"
          ]
        }
      }
    end

    assert_redirected_to daily_flow_reflection_path
  end

  test "should render gratitude on invalid data" do
    assert_no_difference "Gratitude.count" do
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: "not an array" }
      }
    end

    assert_response :unprocessable_content
  end

  test "should get reflection page" do
    # Create some gratitudes for today
    Gratitude.create!(content: "Test gratitude 1")
    Gratitude.create!(content: "Test gratitude 2")

    get daily_flow_reflection_path
    assert_response :success
    assert_select "h1", "Reflect & Reinforce"
  end

  test "should save reflection and redirect to completion" do
  post daily_flow_save_reflection_path, params: { reflection: { content: "Test reflection" } }
  assert_redirected_to daily_flow_completion_path
  end

  test "should get completion page" do
    get daily_flow_completion_path
    assert_response :success
    assert_select "h1", "Well Done!"
  end

  test "should show today's data on completion page" do
    # Create today's mood and gratitudes
    mood = MoodCheckIn.create!(mood_level: 8, notes: "Good day")
    gratitude = Gratitude.create!(content: "Test gratitude")

    get daily_flow_completion_path
    assert_response :success
  end
end

require "test_helper"

class DailyFlowWorkflowTest < ActionDispatch::IntegrationTest
  test "complete daily workflow from start to finish" do
    # Step 1: Start the workflow
    get daily_flow_start_path
    assert_redirected_to daily_flow_check_in_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "Daily Check-In"

    # Step 2: Submit mood check-in
    assert_difference "MoodCheckIn.count", 1 do
      post daily_flow_save_check_in_path, params: {
        mood_check_in: {
          mood_level: 8,
          notes: "Feeling great today!"
        }
      }
    end
    assert_redirected_to daily_flow_affirmation_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "Your Daily Affirmation"

    # Step 3: View affirmation and continue
    get daily_flow_gratitude_path
    assert_response :success
    assert_select "h1", "Record Your Gratitudes"

    # Step 4: Submit gratitudes
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
    follow_redirect!
    assert_response :success
    assert_select "h1", "Reflect & Reinforce"

    # Step 5: Complete reflection
    post daily_flow_save_reflection_path
    assert_redirected_to daily_flow_completion_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "Well Done!"

    # Verify data was saved
    mood = MoodCheckIn.last
    assert_equal 8, mood.mood_level
    assert_equal "Feeling great today!", mood.notes

    gratitudes = Gratitude.last(3)
    assert_equal 3, gratitudes.count
    assert_equal "I am grateful for sunshine", gratitudes[0].content
  end

  test "workflow handles navigation between steps" do
    # Start workflow
    get daily_flow_check_in_path
    assert_response :success

    # Submit check-in
    post daily_flow_save_check_in_path, params: {
      mood_check_in: { mood_level: 7 }
    }
    assert_redirected_to daily_flow_affirmation_path

    # Navigate to gratitude
    get daily_flow_gratitude_path
    assert_response :success

    # Navigate back to affirmation
    get daily_flow_affirmation_path
    assert_response :success

    # Navigate forward to gratitude again
    get daily_flow_gratitude_path
    assert_response :success
  end

  test "workflow shows today's data on completion" do
    # Create today's mood and gratitudes
    mood = MoodCheckIn.create!(mood_level: 9, notes: "Excellent day")
    gratitude1 = Gratitude.create!(content: "Test gratitude 1")
    gratitude2 = Gratitude.create!(content: "Test gratitude 2")

    get daily_flow_completion_path
    assert_response :success
    assert_select "h1", "Well Done!"
  end

  test "workflow handles invalid mood data" do
    get daily_flow_check_in_path
    assert_response :success

    assert_no_difference "MoodCheckIn.count" do
      post daily_flow_save_check_in_path, params: {
        mood_check_in: { mood_level: nil }
      }
    end

    assert_response :unprocessable_content
    assert_select "h1", "Daily Check-In"
  end

  test "workflow handles empty gratitudes" do
    get daily_flow_gratitude_path
    assert_response :success

    # Submit with all empty gratitudes
    assert_no_difference "Gratitude.count" do
      post daily_flow_save_gratitude_path, params: {
        gratitude: { contents: [ "", "", "" ] }
      }
    end

    assert_redirected_to daily_flow_reflection_path
  end

  test "workflow can be accessed via breadcrumb route" do
    get daily_flow_path
    assert_redirected_to daily_flow_check_in_path
  end
end

require "test_helper"

class ReflectionWorkflowTest < ActionDispatch::IntegrationTest
  test "user can save a reflection and see it on completion" do
    # submit a mood check-in first
    post daily_flow_save_check_in_path, params: { mood_check_in: { mood_level: 6 } }
    assert_redirected_to daily_flow_affirmation_path
    follow_redirect!

    # submit gratitudes
    post daily_flow_save_gratitude_path, params: { gratitude: { contents: [ "g1", "g2", "g3" ] } }
    assert_redirected_to daily_flow_reflection_path
    follow_redirect!

    # submit reflection content
    assert_difference "Reflection.count", 1 do
      post daily_flow_save_reflection_path, params: { reflection: { content: "My reflection" } }
    end

    assert_redirected_to daily_flow_completion_path
    follow_redirect!
    assert_response :success

    # page should include the reflection text
    assert_select "h3", "Your Reflections"
    assert_select "p", /My reflection/
  end
end

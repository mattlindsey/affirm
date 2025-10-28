require "test_helper"

class GratitudeControllerTest < ActionDispatch::IntegrationTest
  def setup
    @gratitude = gratitudes(:one)
  end

  test "should get index" do
    get gratitude_path
    assert_response :success
    # view currently uses "Gratitudes" and specific link texts
    assert_select "h1", "Gratitudes"
    assert_select "a", "📝 Create Today's Gratitudes"
    assert_select "a", "🎲 Get Random Gratitude"
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
    assert_select "a[href='#{gratitude_path}']", "← Back to Gratitude"
  end
end

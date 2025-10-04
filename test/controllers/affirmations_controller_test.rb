require "test_helper"

class AffirmationsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @affirmation = affirmations(:one)
  end

  test "should get index" do
    get affirmations_path
    assert_response :success
    assert_select "h1", "Daily Affirmations"
  end

  test "should delete affirmation" do
    assert_difference "Affirmation.count", -1 do
      delete affirmation_path(@affirmation)
    end

    assert_redirected_to affirmations_path
    assert_equal "Affirmation was successfully deleted.", flash[:notice]
  end
end

require "test_helper"

class CheckinsControllerTest < ActionDispatch::IntegrationTest
  def setup
  # Ensure test DB has known state
  MoodCheckIn.destroy_all
  end

  test "should get index and show message when empty" do
    get checkins_path
    assert_response :success
  # title includes a total count span, so match by regex
  assert_select "h1", /Your check-ins/
  assert_select "p", /don't have any check-ins yet/i
  end

  test "should list existing checkins" do
    MoodCheckIn.create!(mood_level: 7, notes: "Feeling good")
    MoodCheckIn.create!(mood_level: 3, notes: "A bit low")

    get checkins_path
    assert_response :success
    assert_select "li", minimum: 2
    assert_select "span", /7\/10/ # mood level display
  end
end

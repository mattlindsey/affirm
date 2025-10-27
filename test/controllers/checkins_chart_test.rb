require "test_helper"

class CheckinsChartTest < ActionDispatch::IntegrationTest
  def setup
    MoodCheckIn.delete_all
    # create a couple of checkins on different days
    MoodCheckIn.create!(mood_level: 5, created_at: Time.zone.now.beginning_of_month + 1.day)
    MoodCheckIn.create!(mood_level: 8, created_at: Time.zone.now.beginning_of_month + 25.days)
  # create multiple check-ins on the same day to assert we pick the highest
  # use day 10 explicitly (index 9 in zero-based arrays)
  same_day = Time.zone.now.beginning_of_month + 9.days
  MoodCheckIn.create!(mood_level: 3, created_at: same_day + 2.hours)
  MoodCheckIn.create!(mood_level: 9, created_at: same_day + 5.hours)
  end

  test "chart canvas exports daily labels and values" do
    get checkins_path
    assert_response :success
    # ensure canvas exists
    assert_select 'canvas[data-controller="checkins-chart"]', 1
    canvas = css_select('canvas[data-controller="checkins-chart"]').first
    labels_json = canvas.attributes["data-checkins-chart-labels-value"]
    values_json = canvas.attributes["data-checkins-chart-values-value"]
    assert labels_json.present?
    assert values_json.present?
    labels = JSON.parse(labels_json)
    values = JSON.parse(values_json)
    # labels should start at '1'
    assert_equal "1", labels.first
    # values length should match number of days in current month
    days_in_month = Time.zone.now.end_of_month.day
    assert_equal days_in_month, values.length
  # The 10th day should reflect the highest mood of that day (pick the max when multiple check-ins)
  tenth_day_index = 9 # zero-based index for day 10
  assert_equal 9, values[tenth_day_index]
  end
end

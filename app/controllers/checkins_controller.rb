class CheckinsController < ApplicationController
  def index
  scope = (defined?(current_user) && current_user) ? current_user.mood_check_ins : MoodCheckIn.all
  @checkins = scope.order(created_at: :desc)
  @total_count = @checkins.count

  # Build daily labels and values for the current month chart.
  # For days with multiple check-ins, use the maximum mood_level for that day.
  start_date = Time.zone.now.beginning_of_month.to_date
  end_date = Time.zone.now.end_of_month.to_date
  days_in_month = (start_date..end_date).to_a

  # Pre-fill labels (day numbers) and default null values
  @daily_labels = days_in_month.map { |d| d.day.to_s }
  # Group checkins by date and pick the maximum mood_level for each day
  grouped = @checkins.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
             .group_by { |c| c.created_at.to_date }
  max_per_day = grouped.transform_values { |arr| arr.map(&:mood_level).max }

  @daily_values = days_in_month.map { |d| max_per_day[d] || nil }
  end
end

class CheckinsController < ApplicationController
  def index
    scope = (defined?(current_user) && current_user) ? current_user.mood_check_ins : MoodCheckIn.all
    @checkins = scope.order(created_at: :desc)
    @total_count = @checkins.count
    # prepare data for the last 12 months chart (oldest -> current month)
    today = Time.zone.today
    end_month = today.beginning_of_month
    months = (0..11).to_a.reverse.map { |i| (end_month - i.months).beginning_of_month }

    # English abbreviated month names
    month_abbr_en = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    @labels = months.map { |m| month_abbr_en[m.month - 1] }

    @values = months.map do |m|
      if m == today.beginning_of_month
        # current month: count from 1st to today
        range_start = m.beginning_of_month
        range_end = today.end_of_day
      else
        range_start = m.beginning_of_month
        range_end = m.end_of_month.end_of_day
      end
      scope.where(created_at: range_start..range_end).count
    end
    
    # Additionally prepare daily data for the current month (1..end_of_month)
    start_of_month = today.beginning_of_month
    end_of_month = today.end_of_month
    days = (1..end_of_month.day).to_a
    @daily_labels = days.map { |d| d.to_s }
    @daily_values = days.map do |day|
      day_start = start_of_month + (day - 1).days
      range_start = day_start.beginning_of_day
      range_end = day_start.end_of_day
      scope.where(created_at: range_start..range_end).count
    end
    # Suggest a goal line slightly above the observed max (rounded to next 10)
    max_daily = @daily_values.max || 0
    @daily_goal = if max_daily > 0
      (( (max_daily.to_f / 10.0).ceil + 1 ) * 10)
    else
      0
    end

    # Prepare last 30 days mood series (average mood per day, values 1..10)
    last_30_end = today
    last_30_start = (today - 29.days)
    last_30_range = last_30_start.beginning_of_day..last_30_end.end_of_day
    last_30_days = (0..29).to_a.map { |i| (last_30_start + i.days).to_date }
    @last_30_labels = last_30_days.map { |d| d.strftime('%b %d') } # e.g. Oct 05
    @last_30_values = last_30_days.map do |d|
      day_scope = scope.where(created_at: d.beginning_of_day..d.end_of_day)
      # compute average mood for the day; if none, use null so chart skips label
      if day_scope.exists?
        # mood is stored in `mood_level` integer column (1..10)
        day_scope.average(:mood_level).to_f.round(1)
      else
        nil
      end
    end
  end
end

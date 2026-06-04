class CheckinsController < ApplicationController
  def index
    @checkins = current_user.mood_check_ins.order(created_at: :desc)
    @total_count = @checkins.count

    start_date = Time.zone.now.beginning_of_month.to_date
    end_date   = Time.zone.now.end_of_month.to_date
    days_in_month = (start_date..end_date).to_a

    @daily_labels = days_in_month.map { |d| d.day.to_s }

    grouped = @checkins.where(created_at: start_date.beginning_of_day..end_date.end_of_day)
                       .group_by { |c| c.created_at.to_date }
    max_per_day = grouped.transform_values { |arr| arr.map(&:mood_level).max }

    @daily_values = days_in_month.map { |d| max_per_day[d] || nil }
  end
end

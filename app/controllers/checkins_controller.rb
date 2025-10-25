class CheckinsController < ApplicationController
  def index
    scope = (defined?(current_user) && current_user) ? current_user.mood_check_ins : MoodCheckIn.all
    @checkins = scope.order(created_at: :desc)
    @total_count = @checkins.count
    # prepare data for a calendar-year checkins chart (Jan..Dec of current year)
    year_start = Time.zone.today.beginning_of_year
    months = (0..11).map { |i| (year_start + i.months).beginning_of_month }

    # English abbreviated month names
    month_abbr_en = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    @labels = months.map { |m| month_abbr_en[m.month - 1] }
    @values = months.map do |m|
      scope.where(created_at: m.beginning_of_month..m.end_of_month).count
    end
  end
end

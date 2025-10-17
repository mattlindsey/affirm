class GratitudeRepository
  def yesterday_gratitude
    Gratitude.where(created_at: 1.day.ago.beginning_of_day..1.day.ago.end_of_day)
             .order(:created_at)
             .first
  end

  def recent_gratitudes(limit: 5)
    Gratitude.order(created_at: :desc).limit(limit)
  end
end

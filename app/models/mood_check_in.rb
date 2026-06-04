class MoodCheckIn < ApplicationRecord
  belongs_to :user, optional: true

  has_many :reflections, dependent: :destroy, inverse_of: :mood_check_in
  validates :mood_level, presence: true, inclusion: { in: 1..10 }

  def mood_emoji
    case mood_level
    when 1..2
      "😢"
    when 3..4
      "😔"
    when 5..6
      "😐"
    when 7..8
      "😊"
    when 9..10
      "😄"
    else
      "😶"
    end
  end

  def mood_description
    case mood_level
    when 1..2
      "Having a tough time"
    when 3..4
      "Feeling low"
    when 5..6
      "Neutral"
    when 7..8
      "Feeling good"
    when 9..10
      "Feeling amazing"
    else
      "Unknown"
    end
  end
end

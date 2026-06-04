class Reflection < ApplicationRecord
  belongs_to :user, optional: true

  belongs_to :mood_check_in

  # content intentionally optional — reflection can be blank
end

class Affirmation < ApplicationRecord
  validates :content, presence: true
end

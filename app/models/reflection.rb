class Reflection < ApplicationRecord
  belongs_to :mood_check_in
  # only declare the association if a User model exists in this app
  belongs_to :user, optional: true if Object.const_defined?("User")

  validates :content, presence: true
end

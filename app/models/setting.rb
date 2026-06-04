class Setting < ApplicationRecord
  belongs_to :user, optional: true

  validates :name, length: { maximum: 255 }, allow_blank: true
end

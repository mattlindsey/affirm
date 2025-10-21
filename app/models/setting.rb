class Setting < ApplicationRecord
  validates :name, length: { maximum: 255 }, allow_blank: true

  def self.instance
    first_or_create
  end
end

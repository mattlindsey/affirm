class Setting < ApplicationRecord
  belongs_to :user, optional: true

  validates :name, length: { maximum: 255 }, allow_blank: true

  def openai_api_key_present?
    openai_api_key.present?
  end
end

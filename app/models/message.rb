class Message < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :conversation, touch: true

  validates :role, presence: true, inclusion: { in: ROLES }
  validates :content, presence: true, length: { maximum: 10_000 }

  scope :chronological, -> { order(created_at: :asc) }
end

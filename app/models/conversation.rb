class Conversation < ApplicationRecord
  CONTEXT_MESSAGE_LIMIT = 50

  belongs_to :user
  has_many :messages, dependent: :destroy

  validates :user, presence: true

  scope :recent, -> { order(updated_at: :desc) }

  def messages_for_llm
    messages.order(created_at: :asc).last(CONTEXT_MESSAGE_LIMIT)
  end
end

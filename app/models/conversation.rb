class Conversation < ApplicationRecord
  CONTEXT_MESSAGE_LIMIT = 50

  belongs_to :user
  has_many :messages, dependent: :destroy

  validates :user, presence: true

  scope :recent, -> { order(updated_at: :desc) }
  scope :with_first_user_message, -> { includes(:messages) }

  def first_user_message
    messages.find { |m| m.role == "user" }&.content
  end

  def messages_for_llm
    messages.order(created_at: :asc).last(CONTEXT_MESSAGE_LIMIT)
  end
end

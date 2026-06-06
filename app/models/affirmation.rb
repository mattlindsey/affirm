class Affirmation < ApplicationRecord
  belongs_to :user, optional: true

  scope :for_user, ->(user) { where(user_id: [ user.id, nil ]) }

  validates :content, presence: true

  def self.generate_ai_affirmation(api_key: nil)
    context = api_key.present? ? RubyLLM.context { |c| c.openai_api_key = api_key } : RubyLLM.context
    chat = context.chat(model: "gpt-4o-mini")
    chat.with_instructions("You are a positive affirmation generator. Create one short, uplifting, and personal affirmation that someone can use for daily motivation. Keep it under 100 characters and make it feel genuine and empowering.")
    chat.ask("Generate one positive affirmation for me.").content
  rescue StandardError
    nil
  end
end

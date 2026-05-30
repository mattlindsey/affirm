class Gratitude < ApplicationRecord
  validates :content, presence: true

  def self.generate_ai_prompt
    chat = RubyLLM.chat(model: "gpt-4o-mini")
    chat.with_instructions("You are a positive gratitude prompt generator.")
    chat.ask("Generate a positive gratitude prompt for me.").content
  rescue StandardError
    nil
  end
end

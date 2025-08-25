class Affirmation < ApplicationRecord
  validates :content, presence: true

  def self.generate_ai_affirmation
    begin
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [
            {
              role: "system",
              content: "You are a positive affirmation generator. Create one short, uplifting, and personal affirmation that someone can use for daily motivation. Keep it under 100 characters and make it feel genuine and empowering."
            },
            {
              role: "user",
              content: "Generate one positive affirmation for me."
            }
          ],
          max_tokens: 100,
          temperature: 0.8
        }
      )

      response.dig("choices", 0, "message", "content")&.strip
    rescue => e
      nil
    end
  end
end

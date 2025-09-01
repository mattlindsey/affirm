class Gratitude < ApplicationRecord
  validates :content, presence: true

  def self.generate_ai_prompt
    begin
      client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
      response = client.chat(
        parameters: {
          model: "gpt-3.5-turbo",
          messages: [
            {
              role: "system",
              content: "You are a positive gratitude prompt generator."
            },
            {
              role: "user",
              content: "Generate a positive gratitude prompt for me."
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

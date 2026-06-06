module Chat
  class ReplyService
    SYSTEM_PROMPT = <<~PROMPT
      You are a warm, supportive wellness companion for the Affirm app — a daily mindfulness
      tool for affirmations, gratitude, and reflection. Be encouraging and concise (2-3 sentences).
      Help users explore their thoughts, celebrate small wins, and build positive habits.
    PROMPT

    Result = Struct.new(:reply, :error, keyword_init: true) do
      def success? = error.nil?
    end

    def self.call(message:, history: [], api_key: nil)
      new(message:, history:, api_key:).call
    end

    def initialize(message:, history: [], api_key: nil)
      @message = message
      @history = history
      @api_key = api_key
    end

    def call
      chat = llm_context.chat(model: "gpt-4o-mini").with_instructions(SYSTEM_PROMPT)

      @history.each do |msg|
        role = msg[:role] == "user" ? :user : :assistant
        chat.messages << RubyLLM::Message.new(role: role, content: msg[:content].to_s)
      end

      response = chat.ask(@message)
      Result.new(reply: response.content)
    rescue RubyLLM::Error => e
      Result.new(error: e.message)
    end
  end
end

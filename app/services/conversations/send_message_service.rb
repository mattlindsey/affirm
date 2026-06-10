module Conversations
  class SendMessageService
    INTRO_MESSAGE = "Hi! I'm your CBT wellness coach. I use Cognitive Behavioral Therapy " \
                    "techniques to help you work through thoughts, moods, and everyday challenges. " \
                    "What situation, thought, mood, or upcoming event would you like to explore today?"

    Result = Struct.new(:success, :conversation, :user_message, :assistant_message, :error, keyword_init: true) do
      def success? = success
    end

    def self.call(user:, message:, conversation: nil)
      new(user:, message:, conversation:).call
    end

    def initialize(user:, message:, conversation: nil)
      @user         = user
      @message      = message
      @conversation = conversation
    end

    def call
      active_conversation, user_message = persist_user_message
      history = prior_history(active_conversation, user_message)

      api_key = @user.setting&.openai_api_key.presence
      llm_result = Chat::ReplyService.call(message: @message, history:, api_key:)

      unless llm_result.success?
        return Result.new(success: false, conversation: active_conversation, error: llm_result.error)
      end

      assistant_message = active_conversation.messages.create!(role: "assistant", content: llm_result.reply)
      Result.new(success: true, conversation: active_conversation, user_message:, assistant_message:)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, error: e.message)
    end

    private

    def prior_history(conversation, user_message)
      conversation.messages
                  .where("id < ?", user_message.id)
                  .order(created_at: :desc)
                  .limit(Conversation::CONTEXT_MESSAGE_LIMIT)
                  .reverse
                  .map { |m| { role: m.role, content: m.content } }
    end

    def persist_user_message
      ActiveRecord::Base.transaction do
        conv = @conversation || @user.conversations.create!
        seed_intro(conv) if @conversation.nil?
        msg = conv.messages.create!(role: "user", content: @message)
        [ conv, msg ]
      end
    end

    def seed_intro(conversation)
      conversation.messages.create!(role: "assistant", content: INTRO_MESSAGE)
    end
  end
end

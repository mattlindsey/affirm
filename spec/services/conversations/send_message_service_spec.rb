require "rails_helper"

RSpec.describe Conversations::SendMessageService do
  let(:user) { create(:user) }

  def stub_llm_success(reply: "I understand how you feel.")
    allow(Chat::ReplyService).to receive(:call).and_return(
      Chat::ReplyService::Result.new(reply:)
    )
  end

  def stub_llm_failure(error: "LLM unavailable")
    allow(Chat::ReplyService).to receive(:call).and_return(
      Chat::ReplyService::Result.new(error:)
    )
  end

  describe "new conversation (conversation: nil)" do
    subject(:result) do
      stub_llm_success
      described_class.call(user:, message: "Hello there")
    end

    it "returns success" do
      expect(result).to be_success
    end

    it "creates a new conversation belonging to the user" do
      expect { result }.to change { user.conversations.count }.by(1)
    end

    it "creates intro + user + assistant messages" do
      expect { result }.to change { Message.count }.by(3)
    end

    it "seeds an intro assistant message as the first message" do
      result
      first_message = result.conversation.messages.chronological.first
      expect(first_message.role).to eq("assistant")
      expect(first_message.content).to include("CBT")
    end

    it "returns the conversation, user_message, and assistant_message" do
      expect(result.conversation).to be_a(Conversation)
      expect(result.user_message.role).to eq("user")
      expect(result.user_message.content).to eq("Hello there")
      expect(result.assistant_message.role).to eq("assistant")
    end

    it "passes the intro message as history context to the LLM" do
      stub_llm_success
      described_class.call(user:, message: "Hello")
      expect(Chat::ReplyService).to have_received(:call).with(
        hash_including(history: [ hash_including(role: "assistant") ])
      )
    end
  end

  describe "existing conversation" do
    let(:conversation) { create(:conversation, user:) }

    before do
      create(:message, conversation:, role: "user", content: "First message")
      create(:message, conversation:, role: "assistant", content: "First reply")
    end

    subject(:result) do
      stub_llm_success
      described_class.call(user:, message: "Follow-up question", conversation:)
    end

    it "returns success" do
      expect(result).to be_success
    end

    it "adds two messages to the existing conversation" do
      expect { result }.to change { conversation.messages.count }.by(2)
    end

    it "does not create a new conversation" do
      expect { result }.not_to change { Conversation.count }
    end

    it "passes prior history to the LLM" do
      stub_llm_success
      described_class.call(user:, message: "Follow-up", conversation:)
      expect(Chat::ReplyService).to have_received(:call).with(
        hash_including(history: [
          { role: "user", content: "First message" },
          { role: "assistant", content: "First reply" }
        ])
      )
    end
  end

  describe "LLM failure path" do
    let(:conversation) { create(:conversation, user:) }

    subject(:result) do
      stub_llm_failure
      described_class.call(user:, message: "Help me", conversation:)
    end

    it "returns failure" do
      expect(result).not_to be_success
    end

    it "persists the user message before the LLM call" do
      expect { result }.to change { conversation.messages.where(role: "user").count }.by(1)
    end

    it "does not save an assistant message" do
      expect { result }.not_to change { conversation.messages.where(role: "assistant").count }
    end

    it "returns the conversation in the result" do
      expect(result.conversation).to eq(conversation)
    end

    it "includes the error message" do
      expect(result.error).to eq("LLM unavailable")
    end
  end

  describe "positive psychology flag" do
    context "when use_positive_psychology: true is passed on a new conversation" do
      subject(:result) do
        stub_llm_success
        described_class.call(user:, message: "Hello", use_positive_psychology: true)
      end

      it "creates the conversation with use_positive_psychology set" do
        expect(result.conversation.use_positive_psychology).to be true
      end

      it "passes use_positive_psychology: true to Chat::ReplyService" do
        result
        expect(Chat::ReplyService).to have_received(:call).with(
          hash_including(use_positive_psychology: true)
        )
      end
    end

    context "when use_positive_psychology is not passed" do
      subject(:result) do
        stub_llm_success
        described_class.call(user:, message: "Hello")
      end

      it "creates the conversation with use_positive_psychology false" do
        expect(result.conversation.use_positive_psychology).to be false
      end

      it "passes use_positive_psychology: false to Chat::ReplyService" do
        result
        expect(Chat::ReplyService).to have_received(:call).with(
          hash_including(use_positive_psychology: false)
        )
      end
    end

    context "when continuing a conversation that already has the flag set" do
      let(:conversation) { create(:conversation, :positive_psychology, user:) }

      it "passes use_positive_psychology: true to Chat::ReplyService" do
        stub_llm_success
        described_class.call(user:, message: "Follow-up", conversation:)
        expect(Chat::ReplyService).to have_received(:call).with(
          hash_including(use_positive_psychology: true)
        )
      end
    end
  end

  describe "messages_for_llm cap" do
    let(:conversation) { create(:conversation, user:) }

    it "sends at most CONTEXT_MESSAGE_LIMIT messages as history" do
      (Conversation::CONTEXT_MESSAGE_LIMIT + 5).times do |i|
        create(:message, conversation:, role: i.even? ? "user" : "assistant")
      end

      stub_llm_success
      described_class.call(user:, message: "New message", conversation:)

      expect(Chat::ReplyService).to have_received(:call).with(
        hash_including(history: have_attributes(length: Conversation::CONTEXT_MESSAGE_LIMIT))
      )
    end
  end
end

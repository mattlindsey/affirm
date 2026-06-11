require "rails_helper"

RSpec.describe Chat::ReplyService, type: :service do
  subject(:service) { described_class.new(message: message, history: history) }

  let(:message) { "How can I practice gratitude today?" }
  let(:history) { [] }
  let(:messages_array) { [] }
  let(:reply_message) { instance_double(RubyLLM::Message, content: "Try writing down three things you're grateful for.") }
  let(:chat_double) do
    instance_double(RubyLLM::Chat, messages: messages_array, ask: reply_message).tap do |d|
      allow(d).to receive(:with_instructions).and_return(d)
    end
  end
  let(:context_double) { instance_double(RubyLLM::Context) }

  before do
    allow(RubyLLM).to receive(:context).and_return(context_double)
    allow(context_double).to receive(:chat).with(model: "gpt-4o-mini").and_return(chat_double)
  end

  describe ".call" do
    it "delegates to a new instance" do
      result = described_class.call(message: message)
      expect(result).to be_a(described_class::Result)
    end
  end

  describe "#call" do
    it "returns a successful result with the AI reply" do
      result = service.call
      expect(result).to be_success
      expect(result.reply).to eq("Try writing down three things you're grateful for.")
    end

    it "asks the LLM with the user message" do
      service.call
      expect(chat_double).to have_received(:ask).with(message)
    end

    it "sets a wellness-focused system prompt" do
      service.call
      expect(chat_double).to have_received(:with_instructions).with(a_string_including("wellness companion"))
    end

    it "uses the CBT system prompt by default" do
      service.call
      expect(chat_double).to have_received(:with_instructions).with(a_string_including("CBT"))
    end

    context "with use_positive_psychology: true" do
      subject(:service) { described_class.new(message: message, history: history, use_positive_psychology: true) }

      it "uses the positive psychology system prompt" do
        service.call
        expect(chat_double).to have_received(:with_instructions).with(a_string_including("Positive Psychology"))
      end

      it "does not use the CBT-only prompt" do
        service.call
        expect(chat_double).to have_received(:with_instructions).with(
          satisfy { |prompt| prompt != Chat::ReplyService::SYSTEM_PROMPT }
        )
      end
    end

    context "with conversation history" do
      let(:history) do
        [
          { role: "user", content: "Hello" },
          { role: "assistant", content: "Hi there!" }
        ]
      end

      it "pushes history messages before asking" do
        service.call
        expect(messages_array.length).to eq(2)
      end

      it "maps user history role to :user" do
        service.call
        expect(messages_array.first.role).to eq(:user)
      end

      it "maps assistant history role to :assistant" do
        service.call
        expect(messages_array.last.role).to eq(:assistant)
      end

      it "preserves history content" do
        service.call
        expect(messages_array.first.content).to eq("Hello")
        expect(messages_array.last.content).to eq("Hi there!")
      end
    end

    context "when RubyLLM raises an error" do
      before { allow(chat_double).to receive(:ask).and_raise(RubyLLM::Error, "API unavailable") }

      it "returns a failed result" do
        result = service.call
        expect(result).not_to be_success
      end

      it "captures the error message" do
        result = service.call
        expect(result.error).to eq("API unavailable")
      end
    end
  end
end

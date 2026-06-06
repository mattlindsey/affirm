require "rails_helper"

RSpec.describe Affirmation, type: :model do
  it { is_expected.to validate_presence_of(:content) }

  it "generate_ai_affirmation is a class method" do
    expect(described_class).to respond_to(:generate_ai_affirmation)
    expect(described_class.new).not_to respond_to(:generate_ai_affirmation)
  end

  describe ".generate_ai_affirmation" do
    let(:context_double) { instance_double(RubyLLM::Context) }
    let(:chat) { instance_double(RubyLLM::Chat) }
    let(:message) { instance_double(RubyLLM::Message, content: "You are enough just as you are.") }

    before do
      allow(RubyLLM).to receive(:context).and_return(context_double)
      allow(context_double).to receive(:chat).with(model: "gpt-4o-mini").and_return(chat)
      allow(chat).to receive(:with_instructions).and_return(chat)
      allow(chat).to receive(:ask).and_return(message)
    end

    it "returns an affirmation string" do
      expect(described_class.generate_ai_affirmation).to eq("You are enough just as you are.")
    end

    it "calls the chat with gpt-4o-mini" do
      described_class.generate_ai_affirmation
      expect(context_double).to have_received(:chat).with(model: "gpt-4o-mini")
    end

    it "returns nil when the API raises an error" do
      allow(RubyLLM).to receive(:context).and_raise(StandardError)
      expect(described_class.generate_ai_affirmation).to be_nil
    end
  end
end

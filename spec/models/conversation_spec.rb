require "rails_helper"

RSpec.describe Conversation, type: :model do
  subject { build(:conversation) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:messages).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:user) }
  end

  describe ".recent" do
    it "orders conversations by updated_at descending" do
      user = create(:user)
      older = create(:conversation, user:, updated_at: 2.days.ago)
      newer = create(:conversation, user:, updated_at: 1.day.ago)

      expect(user.conversations.recent).to eq([ newer, older ])
    end
  end

  describe "#messages_for_llm" do
    it "returns messages in chronological order" do
      conversation = create(:conversation)
      msg2 = create(:message, conversation:, created_at: 2.seconds.ago)
      msg1 = create(:message, conversation:, created_at: 3.seconds.ago)

      expect(conversation.messages_for_llm).to eq([ msg1, msg2 ])
    end

    it "returns at most CONTEXT_MESSAGE_LIMIT messages" do
      conversation = create(:conversation)
      (Conversation::CONTEXT_MESSAGE_LIMIT + 5).times do
        create(:message, conversation:)
      end

      expect(conversation.messages_for_llm.length).to eq(Conversation::CONTEXT_MESSAGE_LIMIT)
    end

    it "returns the most recent messages when over the limit" do
      conversation = create(:conversation)
      old_msg = create(:message, conversation:, created_at: 1.hour.ago, content: "old")
      Conversation::CONTEXT_MESSAGE_LIMIT.times do
        create(:message, conversation:)
      end

      expect(conversation.messages_for_llm).not_to include(old_msg)
    end
  end
end

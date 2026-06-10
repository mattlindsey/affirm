require "rails_helper"

RSpec.describe ConversationPolicy, type: :policy do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let(:conversation) { create(:conversation, user:) }

  describe "#show?" do
    it "allows the owner" do
      expect(described_class.new(user, conversation).show?).to be true
    end

    it "denies a different user" do
      expect(described_class.new(other, conversation).show?).to be false
    end
  end

  describe "#create?" do
    it "allows any authenticated user" do
      expect(described_class.new(user, Conversation.new).create?).to be true
    end
  end

  describe "#index?" do
    it "allows any authenticated user" do
      expect(described_class.new(user, Conversation.new).index?).to be true
    end
  end

  describe "Scope" do
    it "returns only the current user's conversations" do
      own  = create(:conversation, user:)
      create(:conversation, user: other)

      result = described_class::Scope.new(user, Conversation.all).resolve
      expect(result).to contain_exactly(own)
    end
  end
end

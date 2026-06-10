require "rails_helper"

RSpec.describe Message, type: :model do
  subject { build(:message) }

  describe "associations" do
    it { is_expected.to belong_to(:conversation) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_inclusion_of(:role).in_array(Message::ROLES) }
    it { is_expected.to validate_presence_of(:content) }
    it { is_expected.to validate_length_of(:content).is_at_most(10_000) }
  end

  describe "touch: true" do
    it "bumps conversation.updated_at when a message is created" do
      conversation = create(:conversation)
      original_updated_at = conversation.updated_at

      travel 1.second do
        create(:message, conversation:)
        expect(conversation.reload.updated_at).to be > original_updated_at
      end
    end
  end

  describe ".chronological" do
    it "orders messages by created_at ascending" do
      conversation = create(:conversation)
      msg2 = create(:message, conversation:, created_at: 2.seconds.ago)
      msg1 = create(:message, conversation:, created_at: 3.seconds.ago)

      expect(conversation.messages.chronological).to eq([ msg1, msg2 ])
    end
  end
end

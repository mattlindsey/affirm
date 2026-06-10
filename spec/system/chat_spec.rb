require "rails_helper"

RSpec.describe "Chat — US1: conversations survive page reload", type: :system do
  before { driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]) }

  context "when the user has an existing conversation with messages" do
    let!(:user)         { sign_in_as_test_user }
    let!(:conversation) { create(:conversation, user:) }

    before do
      create(:message, conversation:, role: "user",      content: "I'm feeling anxious today")
      create(:message, conversation:, role: "assistant",  content: "I hear you. Can you tell me more?")
      create(:message, conversation:, role: "user",      content: "I have a big presentation")
      create(:message, conversation:, role: "assistant",  content: "That's understandable. What are you most worried about?")
      create(:message, conversation:, role: "user",      content: "That I'll forget everything")
      create(:message, conversation:, role: "assistant",  content: "Let's work through that fear together.")
    end

    it "displays all messages and keeps them after a page reload" do
      visit conversation_path(conversation)

      expect(page).to have_css(".chat-msg", count: 6)
      expect(page).to have_css(".chat-msg.user",      text: "I'm feeling anxious today")
      expect(page).to have_css(".chat-msg.assistant", text: "I hear you. Can you tell me more?")
      expect(page).to have_css(".chat-msg.user",      text: "That I'll forget everything")

      visit current_path

      expect(page).to have_css(".chat-msg", count: 6)
      expect(page).to have_css(".chat-msg.user", text: "I'm feeling anxious today")
      expect(page).to have_css(".chat-msg.user", text: "I have a big presentation")
      expect(page).to have_css(".chat-msg.user", text: "That I'll forget everything")
    end

    it "shows the new conversation form when visiting the index" do
      visit conversations_path
      expect(page).to have_css("input[name='message']")
    end
  end

  context "when the user has no conversations" do
    before { sign_in_as_test_user }

    it "shows blank state with message form" do
      visit conversations_path

      expect(page).to have_text("Hi!")
      expect(page).to have_css("input[name='message']")
      expect(page).to have_button("Send")
    end
  end

  context "US2 — view and navigate past conversations" do
    let!(:user)  { sign_in_as_test_user }
    let!(:conv1) { create(:conversation, user:, updated_at: 1.hour.ago) }
    let!(:conv2) { create(:conversation, user:, updated_at: 2.hours.ago) }

    before do
      create(:message, conversation: conv1, role: "user", content: "Conv1 message")
      create(:message, conversation: conv2, role: "user", content: "Conv2 message")
    end

    it "shows a sidebar with both conversations and allows navigating to another" do
      visit conversation_path(conv1)

      expect(page).to have_css("#conversation-sidebar li", minimum: 2)

      within("#conversation-sidebar") do
        find("a[href='#{conversation_path(conv2)}']").click
      end

      expect(page).to have_current_path(conversation_path(conv2))
      expect(page).to have_css(".chat-msg.user", text: "Conv2 message")
    end

    it "highlights the current conversation in the sidebar" do
      visit conversation_path(conv1)

      within("#conversation-sidebar") do
        expect(page).to have_css("a.bg-sky-100.font-semibold")
      end
    end
  end

  context "US3 — start a new conversation while viewing an existing one" do
    let!(:user)  { sign_in_as_test_user }
    let!(:conv1) { create(:conversation, user:) }

    before do
      create(:message, conversation: conv1, role: "user",     content: "First conv message")
      create(:message, conversation: conv1, role: "assistant", content: "First conv reply")
    end

    it "shows the new conversation form when clicking + New from the sidebar" do
      visit conversation_path(conv1)

      within("#conversation-sidebar") do
        click_link "+ New"
      end

      expect(page).to have_current_path(conversations_path)
      expect(page).to have_css("input[name='message']")
    end

    it "the index shows existing conversations in the sidebar" do
      visit conversations_path

      expect(page).to have_css("#conversation-sidebar")
      expect(page).to have_css("input[name='message']")
    end
  end
end

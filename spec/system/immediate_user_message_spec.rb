require "rails_helper"

RSpec.describe "Chat — the typed message appears before the reply arrives", type: :system do
  before { driven_by(:selenium, using: :headless_chrome, screen_size: [ 1400, 900 ]) }

  let!(:user)         { sign_in_as_test_user }
  let!(:conversation) { create(:conversation, user:) }

  # A deliberately slow reply so the assertions land while the request is still
  # in flight — that window is exactly what issue #166 is about.
  before do
    allow(Chat::ReplyService).to receive(:call) do
      sleep 3
      Chat::ReplyService::Result.new(reply: "Thanks for telling me.")
    end
  end

  def send_message(text)
    find("input[name='message']").set(text)
    click_button "Send"
  end

  it "shows the message and a thinking indicator while waiting, then the reply" do
    visit conversation_path(conversation)
    send_message("I'm feeling anxious")

    expect(page).to have_css(".chat-msg.user", text: "I'm feeling anxious", wait: 2)
    expect(page).to have_css("#thinking", wait: 2)
    expect(page).to have_no_css(".chat-msg.assistant", text: "Thanks for telling me.")

    expect(page).to have_css(".chat-msg.assistant", text: "Thanks for telling me.", wait: 10)
    expect(page).to have_no_css("#thinking")
    expect(page).to have_css(".chat-msg.user", text: "I'm feeling anxious", count: 1)
  end

  it "clears the input as soon as the message is sent" do
    visit conversation_path(conversation)
    send_message("Clear me")

    expect(page).to have_css(".chat-msg.user", text: "Clear me", wait: 2)
    expect(find("input[name='message']").value).to eq("")
  end

  it "still persists the message that was optimistically rendered" do
    visit conversation_path(conversation)
    send_message("Persist me")

    expect(page).to have_css(".chat-msg.assistant", text: "Thanks for telling me.", wait: 10)
    expect(conversation.messages.where(role: "user").pluck(:content)).to eq([ "Persist me" ])
  end

  context "when the LLM fails" do
    before do
      allow(Chat::ReplyService).to receive(:call) do
        sleep 1
        Chat::ReplyService::Result.new(error: "boom")
      end
    end

    it "keeps the user message on screen and drops the thinking indicator" do
      visit conversation_path(conversation)
      send_message("This will fail")

      expect(page).to have_css(".chat-msg.assistant", text: "couldn't respond", wait: 10)
      expect(page).to have_no_css("#thinking")
      expect(page).to have_css(".chat-msg.user", text: "This will fail", count: 1)
    end
  end

  context "from the new-conversation page" do
    it "shows the message immediately before the conversation page loads" do
      visit conversations_path
      send_message("Starting fresh")

      expect(page).to have_css(".chat-msg.user", text: "Starting fresh", wait: 2)
      expect(page).to have_css("#thinking", wait: 2)

      expect(page).to have_css(".chat-msg.assistant", text: "Thanks for telling me.", wait: 10)
      expect(page).to have_css(".chat-msg.user", text: "Starting fresh", count: 1)
    end
  end
end

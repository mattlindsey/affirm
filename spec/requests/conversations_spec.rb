require "rails_helper"

RSpec.describe "Conversations", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }

  def sign_in(u)
    post login_path, params: { email: u.email, password: "password123" }
  end

  describe "GET /conversations (index)" do
    context "when unauthenticated" do
      it "redirects to login" do
        get conversations_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated with no conversations" do
      before { sign_in(user) }

      it "renders the index with the intro message" do
        get conversations_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("CBT wellness coach")
      end

      it "renders a message input form" do
        get conversations_path
        expect(response.body).to include('name="message"')
      end
    end

    context "when authenticated with existing conversations" do
      before do
        sign_in(user)
        create(:conversation, user:)
      end

      it "renders the index with a new conversation form" do
        get conversations_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('name="message"')
      end
    end
  end

  describe "GET /conversations/:id (show)" do
    let(:conversation) { create(:conversation, user:) }

    before { create(:message, conversation:) }

    context "when unauthenticated" do
      it "redirects to login" do
        get conversation_path(conversation)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated as the owner" do
      before { sign_in(user) }

      it "returns ok" do
        get conversation_path(conversation)
        expect(response).to have_http_status(:ok)
      end

      it "shows the conversation messages" do
        get conversation_path(conversation)
        expect(response.body).to include(conversation.messages.first.content)
      end

      it "loads @conversations for the sidebar" do
        get conversation_path(conversation)
        expect(controller.instance_variable_get(:@conversations)).to include(conversation)
      end

      it "does not include other users' conversations in the sidebar" do
        other_conv = create(:conversation, user: other)
        get conversation_path(conversation)
        expect(controller.instance_variable_get(:@conversations)).not_to include(other_conv)
      end
    end

    context "when authenticated as a different user" do
      before { sign_in(other) }

      it "returns 404" do
        get conversation_path(conversation)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /conversations (create)" do
    context "when unauthenticated" do
      it "redirects to login" do
        post conversations_path, params: { message: "Hello" }
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated" do
      before do
        sign_in(user)
        allow(Conversations::SendMessageService).to receive(:call).and_return(
          Conversations::SendMessageService::Result.new(
            success: true,
            conversation: create(:conversation, user:),
            user_message: build(:message),
            assistant_message: build(:message, :assistant)
          )
        )
      end

      it "calls SendMessageService without an existing conversation" do
        post conversations_path, params: { message: "Hello" }
        expect(Conversations::SendMessageService).to have_received(:call).with(
          hash_including(user: user, message: "Hello")
        )
      end

      it "redirects to the new conversation on success" do
        post conversations_path, params: { message: "Hello" }
        expect(response).to redirect_to(conversation_path(Conversation.last))
      end
    end

    context "when SendMessageService fails with no conversation created" do
      before do
        sign_in(user)
        allow(Conversations::SendMessageService).to receive(:call).and_return(
          Conversations::SendMessageService::Result.new(success: false, error: "invalid")
        )
      end

      it "redirects to conversations index" do
        post conversations_path, params: { message: "Hello" }
        expect(response).to redirect_to(conversations_path)
      end
    end

    context "when SendMessageService fails with a conversation already created" do
      let(:partial_conversation) { create(:conversation, user:) }

      before do
        sign_in(user)
        allow(Conversations::SendMessageService).to receive(:call).and_return(
          Conversations::SendMessageService::Result.new(
            success:      false,
            conversation: partial_conversation,
            error:        "LLM unavailable"
          )
        )
      end

      it "redirects to the conversation so the user can retry" do
        post conversations_path, params: { message: "Hello" }
        expect(response).to redirect_to(conversation_path(partial_conversation))
      end
    end

    context "US3 — new conversation creates a separate record" do
      before do
        sign_in(user)
        allow(Chat::ReplyService).to receive(:call).and_return(
          Chat::ReplyService::Result.new(reply: "Got it!")
        )
      end

      it "creates a new conversation each time" do
        expect {
          post conversations_path, params: { message: "First" }
        }.to change { Conversation.count }.by(1)
      end

      it "a second create produces a separate conversation record" do
        post conversations_path, params: { message: "First" }
        expect {
          post conversations_path, params: { message: "Second" }
        }.to change { Conversation.count }.by(1)
        expect(Conversation.count).to eq(2)
      end
    end
  end
end

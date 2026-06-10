require "rails_helper"

RSpec.describe "Messages", type: :request do
  let(:user)         { create(:user) }
  let(:other)        { create(:user) }
  let(:conversation) { create(:conversation, user:) }

  def sign_in(u)
    post login_path, params: { email: u.email, password: "password123" }
  end

  describe "POST /conversations/:conversation_id/messages" do
    context "when unauthenticated" do
      it "redirects to login" do
        post conversation_messages_path(conversation), params: { message: "Hello" }
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated as the owner" do
      let(:user_msg)      { create(:message, conversation:) }
      let(:assistant_msg) { create(:message, conversation:, role: "assistant") }

      before do
        sign_in(user)
        allow(Conversations::SendMessageService).to receive(:call).and_return(
          Conversations::SendMessageService::Result.new(
            success:           true,
            conversation:,
            user_message:      user_msg,
            assistant_message: assistant_msg
          )
        )
      end

      it "returns a Turbo Stream response" do
        post conversation_messages_path(conversation),
             params: { message: "Hello" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include("text/vnd.turbo-stream.html")
      end

      it "calls SendMessageService with the existing conversation" do
        post conversation_messages_path(conversation),
             params: { message: "Hello" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(Conversations::SendMessageService).to have_received(:call).with(
          hash_including(conversation:)
        )
      end

      it "falls back to redirect on HTML format" do
        post conversation_messages_path(conversation), params: { message: "Hello" }
        expect(response).to redirect_to(conversation_path(conversation))
      end
    end

    context "when LLM fails" do
      before do
        sign_in(user)
        allow(Conversations::SendMessageService).to receive(:call).and_return(
          Conversations::SendMessageService::Result.new(
            success: false,
            conversation:,
            error:   "LLM unavailable"
          )
        )
      end

      it "returns a Turbo Stream error response" do
        post conversation_messages_path(conversation),
             params: { message: "Hello" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("turbo-stream")
      end
    end

    context "when the conversation belongs to a different user" do
      before { sign_in(other) }

      it "returns 404" do
        post conversation_messages_path(conversation),
             params: { message: "Hello" },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end

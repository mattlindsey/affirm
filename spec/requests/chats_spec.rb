require "rails_helper"

RSpec.describe "Chats", type: :request do
  describe "POST /chat" do
    context "when not authenticated" do
      it "redirects to login" do
        post chat_path, params: { message: "Hello" }, as: :json
        expect(response).to redirect_to(login_path)
      end
    end

    context "when authenticated" do
      let(:successful_result) { Chat::ReplyService::Result.new(reply: "Great question!") }
      let(:failed_result)     { Chat::ReplyService::Result.new(error: "API unavailable") }

      before do
        sign_in_test_user
        allow(Chat::ReplyService).to receive(:call).and_return(successful_result)
      end

      it "returns 200 with the AI reply" do
        post chat_path, params: { message: "Hello" }, as: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["reply"]).to eq("Great question!")
      end

      it "passes the message to the service" do
        post chat_path, params: { message: "What is gratitude?" }, as: :json
        expect(Chat::ReplyService).to have_received(:call).with(hash_including(message: "What is gratitude?"))
      end

      it "passes an empty history when none is provided" do
        post chat_path, params: { message: "Hello" }, as: :json
        expect(Chat::ReplyService).to have_received(:call).with(hash_including(history: []))
      end

      context "with conversation history" do
        let(:history) do
          [ { role: "user", content: "Hi" }, { role: "assistant", content: "Hello!" } ]
        end

        it "passes history to the service" do
          post chat_path, params: { message: "Follow up", history: history }, as: :json
          expect(Chat::ReplyService).to have_received(:call).with(
            hash_including(history: [
              { role: "user", content: "Hi" },
              { role: "assistant", content: "Hello!" }
            ])
          )
        end
      end

      context "when the service fails" do
        before { allow(Chat::ReplyService).to receive(:call).and_return(failed_result) }

        it "returns 422" do
          post chat_path, params: { message: "Hello" }, as: :json
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns a user-facing error message" do
          post chat_path, params: { message: "Hello" }, as: :json
          expect(response.parsed_body["error"]).to be_present
        end
      end
    end
  end
end

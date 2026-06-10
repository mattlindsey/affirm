class ConversationsController < ApplicationController
  before_action :set_conversation, only: :show

  def index
    authorize Conversation
    @conversations = policy_scope(Conversation).recent
    render :index
  end

  def show
    @messages      = @conversation.messages.chronological
    @conversations = policy_scope(Conversation).recent
  end

  def create
    authorize Conversation
    result = Conversations::SendMessageService.call(
      user:    current_user,
      message: params[:message].to_s.strip
    )

    if result.success?
      redirect_to conversation_path(result.conversation)
    elsif result.conversation
      redirect_to conversation_path(result.conversation), alert: "Sorry, I couldn't respond right now. Please try again."
    else
      redirect_to conversations_path, alert: "Sorry, something went wrong. Please try again."
    end
  end

  private

  def set_conversation
    @conversation = policy_scope(Conversation).find(params[:id])
    authorize @conversation
  end
end

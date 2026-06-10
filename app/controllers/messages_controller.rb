class MessagesController < ApplicationController
  before_action :set_conversation

  def create
    result = Conversations::SendMessageService.call(
      user:         current_user,
      message:      params[:message].to_s.strip,
      conversation: @conversation
    )

    if result.success?
      @user_message      = result.user_message
      @assistant_message = result.assistant_message
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to conversation_path(@conversation) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.append("messages", partial: "conversations/error", locals: { message: "Sorry, I couldn't respond right now. Please try again." }) }
        format.html { redirect_to conversation_path(@conversation), alert: "Sorry, I couldn't respond right now." }
      end
    end
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
    authorize @conversation, :show?
  end
end

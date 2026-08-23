class MessagesController < ApplicationController
  ERROR_MESSAGE = "Sorry, I couldn't respond right now. Please try again.".freeze

  before_action :set_conversation

  def create
    result = Conversations::SendMessageService.call(
      user:         current_user,
      message:      params[:message].to_s.strip,
      conversation: @conversation
    )

    @user_message = result.user_message

    if result.success?
      @assistant_message = result.assistant_message
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to conversation_path(@conversation) }
      end
    else
      respond_to do |format|
        format.turbo_stream { render :error, locals: { error_message: ERROR_MESSAGE } }
        format.html { redirect_to conversation_path(@conversation), alert: ERROR_MESSAGE }
      end
    end
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
    authorize @conversation, :show?
  end
end

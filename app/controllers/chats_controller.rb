class ChatsController < ApplicationController
  def create
    history = permitted_history.map { |m| { role: m[:role], content: m[:content] } }
    api_key = current_user.setting&.openai_api_key.presence
    result = Chat::ReplyService.call(message: params[:message].to_s, history:, api_key:)

    if result.success?
      render json: { reply: result.reply }
    else
      render json: { error: "Sorry, I couldn't respond right now." }, status: :unprocessable_entity
    end
  end

  private

  def permitted_history
    params.fetch(:history, []).filter_map do |msg|
      next unless msg.is_a?(ActionController::Parameters)
      role = msg[:role].to_s
      next unless %w[user assistant].include?(role)
      { role:, content: msg[:content].to_s }
    end
  end
end

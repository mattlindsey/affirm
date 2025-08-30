class GratitudeController < ApplicationController
  def index
    @gratitudes = Gratitude.order(created_at: :asc)
  end

  def random
    @gratitude = Gratitude.order("RANDOM()").first
  end

  def create
    # Simple action to render the form
  end

  def store
    if create_gratitudes
      redirect_to gratitude_path, notice: "Today's gratitudes created successfully!"
    else
      render :create, status: :unprocessable_content
    end
  end

  private

  def create_gratitudes
    begin
      params = gratitude_params
      return false unless params[:contents].is_a?(Array)

      params[:contents].each do |content|
        next if content.blank?

        gratitude = Gratitude.new(content: content.strip)
        return false unless gratitude.save
      end
      true
    rescue ActionController::ParameterMissing
      false
    end
  end

  def gratitude_params
    params.require(:gratitude).permit(contents: [])
  end
end

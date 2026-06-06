class AddOpenaiApiKeyToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :openai_api_key, :string
  end
end

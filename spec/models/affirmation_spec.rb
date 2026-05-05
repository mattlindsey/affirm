require "rails_helper"

RSpec.describe Affirmation, type: :model do
  before do
    @original_api_key = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "test_api_key"
  end

  after do
    ENV["OPENAI_API_KEY"] = @original_api_key
  end

  it "generate_ai_affirmation method exists" do
    expect(Affirmation).to respond_to(:generate_ai_affirmation)
  end

  it "generate_ai_affirmation returns nil when no API key" do
    ENV["OPENAI_API_KEY"] = nil
    expect(Affirmation.generate_ai_affirmation).to be_nil
  end

  it "generate_ai_affirmation returns nil when API key is empty" do
    ENV["OPENAI_API_KEY"] = ""
    expect(Affirmation.generate_ai_affirmation).to be_nil
  end

  it "generate_ai_affirmation handles malformed API key gracefully" do
    ENV["OPENAI_API_KEY"] = "invalid_key"
    result = Affirmation.generate_ai_affirmation
    expect(result.nil? || result.is_a?(String)).to be true
  end

  it "generate_ai_affirmation method signature is correct" do
    expect(Affirmation.method(:generate_ai_affirmation).arity).to eq(0)
  end

  it "generate_ai_affirmation is a class method" do
    expect(Affirmation).to respond_to(:generate_ai_affirmation)
    expect(Affirmation.new).not_to respond_to(:generate_ai_affirmation)
  end
end

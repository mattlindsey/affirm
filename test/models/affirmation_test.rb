require "test_helper"

class AffirmationTest < ActiveSupport::TestCase
  setup do
    @original_api_key = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "test_api_key"
  end

  teardown do
    ENV["OPENAI_API_KEY"] = @original_api_key
  end

  test "generate_ai_affirmation method exists" do
    assert_respond_to Affirmation, :generate_ai_affirmation
  end

  test "generate_ai_affirmation returns nil when no API key" do
    ENV["OPENAI_API_KEY"] = nil
    result = Affirmation.generate_ai_affirmation
    assert_nil result
  end

  test "generate_ai_affirmation returns nil when API key is empty" do
    ENV["OPENAI_API_KEY"] = ""
    result = Affirmation.generate_ai_affirmation
    assert_nil result
  end

  test "generate_ai_affirmation handles malformed API key gracefully" do
    ENV["OPENAI_API_KEY"] = "invalid_key"
    # This should fail gracefully and return nil
    result = Affirmation.generate_ai_affirmation
    # We can't predict the exact behavior without a real API key,
    # but it should either return a result or nil, not crash
    assert result.nil? || result.is_a?(String)
  end

  test "generate_ai_affirmation method signature is correct" do
    method = Affirmation.method(:generate_ai_affirmation)
    assert_equal 0, method.arity
  end

  test "generate_ai_affirmation is a class method" do
    assert Affirmation.respond_to?(:generate_ai_affirmation)
    refute Affirmation.new.respond_to?(:generate_ai_affirmation)
  end
end

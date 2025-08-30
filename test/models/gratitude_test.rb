require "test_helper"

class GratitudeTest < ActiveSupport::TestCase
  def setup
    @gratitude = Gratitude.new(content: "I am grateful for this test")
  end

  test "should be valid with valid content" do
    assert @gratitude.valid?
  end

  test "should require content" do
    @gratitude.content = nil
    refute @gratitude.valid?
    assert_includes @gratitude.errors[:content], "can't be blank"
  end

  test "should require non-empty content" do
    @gratitude.content = ""
    refute @gratitude.valid?
    assert_includes @gratitude.errors[:content], "can't be blank"
  end

  test "should require non-whitespace content" do
    @gratitude.content = "   "
    refute @gratitude.valid?
    assert_includes @gratitude.errors[:content], "can't be blank"
  end

  test "should save with valid content" do
    assert_difference "Gratitude.count" do
      @gratitude.save
    end
  end

  test "should have created_at timestamp" do
    @gratitude.save
    assert_not_nil @gratitude.created_at
  end

  test "should have updated_at timestamp" do
    @gratitude.save
    assert_not_nil @gratitude.updated_at
  end

  test "should allow long content" do
    long_content = "I am grateful for " + "a" * 1000
    @gratitude.content = long_content
    assert @gratitude.valid?
  end

  test "should allow special characters in content" do
    @gratitude.content = "I'm grateful for: coffee ☕, music 🎵, and friends! ❤️"
    assert @gratitude.valid?
  end
end

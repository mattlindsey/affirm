require "test_helper"

class MoodCheckInTest < ActiveSupport::TestCase
  def setup
    @mood_check_in = MoodCheckIn.new
  end

  test "should be valid with valid attributes" do
    @mood_check_in.mood_level = 7
    @mood_check_in.notes = "Feeling good today"

    assert @mood_check_in.valid?
  end

  test "should be valid with just mood level" do
    @mood_check_in.mood_level = 5

    assert @mood_check_in.valid?
  end

  test "should not be valid without mood level" do
    @mood_check_in.notes = "No mood level"

    assert_not @mood_check_in.valid?
    assert_includes @mood_check_in.errors[:mood_level], "can't be blank"
  end

  test "should not be valid with mood level below 1" do
  @mood_check_in.mood_level = 0

  assert_not @mood_check_in.valid?
  assert_includes @mood_check_in.errors[:mood_level], "is not included in the list"
  end

  test "should not be valid with mood level above 10" do
    @mood_check_in.mood_level = 11

    assert_not @mood_check_in.valid?
    assert_includes @mood_check_in.errors[:mood_level], "is not included in the list"
  end

  test "should return correct emoji for mood level 1-2" do
    @mood_check_in.mood_level = 1
    assert_equal "😢", @mood_check_in.mood_emoji

    @mood_check_in.mood_level = 2
    assert_equal "😢", @mood_check_in.mood_emoji
  end

  test "should return correct emoji for mood level 3-4" do
    @mood_check_in.mood_level = 3
    assert_equal "😔", @mood_check_in.mood_emoji

    @mood_check_in.mood_level = 4
    assert_equal "😔", @mood_check_in.mood_emoji
  end

  test "should return correct emoji for mood level 5-6" do
    @mood_check_in.mood_level = 5
    assert_equal "😐", @mood_check_in.mood_emoji

    @mood_check_in.mood_level = 6
    assert_equal "😐", @mood_check_in.mood_emoji
  end

  test "should return correct emoji for mood level 7-8" do
    @mood_check_in.mood_level = 7
    assert_equal "😊", @mood_check_in.mood_emoji

    @mood_check_in.mood_level = 8
    assert_equal "😊", @mood_check_in.mood_emoji
  end

  test "should return correct emoji for mood level 9-10" do
    @mood_check_in.mood_level = 9
    assert_equal "😄", @mood_check_in.mood_emoji

    @mood_check_in.mood_level = 10
    assert_equal "😄", @mood_check_in.mood_emoji
  end

  test "should return correct description for mood level 1-2" do
    @mood_check_in.mood_level = 1
    assert_equal "Having a tough time", @mood_check_in.mood_description

    @mood_check_in.mood_level = 2
    assert_equal "Having a tough time", @mood_check_in.mood_description
  end

  test "should return correct description for mood level 3-4" do
    @mood_check_in.mood_level = 3
    assert_equal "Feeling low", @mood_check_in.mood_description

    @mood_check_in.mood_level = 4
    assert_equal "Feeling low", @mood_check_in.mood_description
  end

  test "should return correct description for mood level 5-6" do
    @mood_check_in.mood_level = 5
    assert_equal "Neutral", @mood_check_in.mood_description

    @mood_check_in.mood_level = 6
    assert_equal "Neutral", @mood_check_in.mood_description
  end

  test "should return correct description for mood level 7-8" do
    @mood_check_in.mood_level = 7
    assert_equal "Feeling good", @mood_check_in.mood_description

    @mood_check_in.mood_level = 8
    assert_equal "Feeling good", @mood_check_in.mood_description
  end

  test "should return correct description for mood level 9-10" do
    @mood_check_in.mood_level = 9
    assert_equal "Feeling amazing", @mood_check_in.mood_description

    @mood_check_in.mood_level = 10
    assert_equal "Feeling amazing", @mood_check_in.mood_description
  end

  test "should save valid mood check-in to database" do
    @mood_check_in.mood_level = 8
    @mood_check_in.notes = "Great day!"

    assert_difference("MoodCheckIn.count", 1) do
      assert @mood_check_in.save
    end

    # Verify the record was saved with correct attributes
    saved_record = MoodCheckIn.last
    assert_equal 8, saved_record.mood_level
    assert_equal "Great day!", saved_record.notes
    assert_not_nil saved_record.created_at
  end

  test "should not save invalid mood check-in" do
    @mood_check_in.mood_level = 15

    assert_no_difference("MoodCheckIn.count") do
      assert_not @mood_check_in.save
    end

    assert_includes @mood_check_in.errors[:mood_level], "is not included in the list"
  end
end

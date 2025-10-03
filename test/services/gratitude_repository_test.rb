require "test_helper"

class GratitudeRepositoryTest < ActiveSupport::TestCase
  def setup
    @repository = GratitudeRepository.new
  end

  test "should return yesterday's gratitude when it exists" do
    # Create a gratitude from yesterday
    yesterday_gratitude = Gratitude.create!(content: "coffee with Sarah")
    yesterday_gratitude.update_column(:created_at, 1.day.ago)

    # Create a gratitude from today (should not be returned)
    today_gratitude = Gratitude.create!(content: "today's gratitude")

    result = @repository.yesterday_gratitude

    assert_equal yesterday_gratitude, result
    assert_not_equal today_gratitude, result
  end

  test "should return nil when no yesterday's gratitude exists" do
    # Create only today's gratitude
    Gratitude.create!(content: "today's gratitude")

    result = @repository.yesterday_gratitude

    assert_nil result
  end

  test "should return the first gratitude when multiple exist from yesterday" do
    # Create multiple gratitudes from yesterday
    first_gratitude = Gratitude.create!(content: "first gratitude")
    first_gratitude.update_column(:created_at, 1.day.ago)

    second_gratitude = Gratitude.create!(content: "second gratitude")
    second_gratitude.update_column(:created_at, 1.day.ago + 1.hour)

    result = @repository.yesterday_gratitude

    assert_equal first_gratitude, result
  end

  test "should return recent gratitudes in descending order" do
    # Clear existing gratitudes to avoid interference
    Gratitude.destroy_all

    # Create gratitudes with different timestamps
    old_gratitude = Gratitude.create!(content: "old gratitude")
    old_gratitude.update_column(:created_at, 3.days.ago)

    recent_gratitude = Gratitude.create!(content: "recent gratitude")
    recent_gratitude.update_column(:created_at, 1.day.ago)

    newest_gratitude = Gratitude.create!(content: "newest gratitude")

    result = @repository.recent_gratitudes(limit: 2)

    assert_equal 2, result.count
    assert_equal newest_gratitude, result.first
    assert_equal recent_gratitude, result.second
  end

  test "should respect limit parameter for recent gratitudes" do
    # Clear existing gratitudes to avoid interference
    Gratitude.destroy_all

    # Create 5 gratitudes
    5.times do |i|
      gratitude = Gratitude.create!(content: "gratitude #{i}")
      gratitude.update_column(:created_at, i.days.ago)
    end

    result = @repository.recent_gratitudes(limit: 3)

    assert_equal 3, result.count
  end

  test "should return all gratitudes when limit exceeds count" do
    # Clear existing gratitudes to avoid interference
    Gratitude.destroy_all

    # Create only 2 gratitudes
    2.times do |i|
      Gratitude.create!(content: "gratitude #{i}")
    end

    result = @repository.recent_gratitudes(limit: 5)

    assert_equal 2, result.count
  end

  test "should return empty array when no gratitudes exist" do
    Gratitude.destroy_all

    result = @repository.recent_gratitudes

    assert_empty result
  end
end

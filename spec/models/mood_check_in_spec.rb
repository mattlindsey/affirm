require "rails_helper"

RSpec.describe MoodCheckIn, type: :model do
  subject(:mood_check_in) { build(:mood_check_in) }

  it "is valid with valid attributes" do
    expect(mood_check_in).to be_valid
  end

  it "is valid with just mood level" do
    mood_check_in.notes = nil
    expect(mood_check_in).to be_valid
  end

  it "is invalid without mood level" do
    mood_check_in.mood_level = nil
    expect(mood_check_in).not_to be_valid
    expect(mood_check_in.errors[:mood_level]).to include("can't be blank")
  end

  it "is invalid with mood level below 1" do
    mood_check_in.mood_level = 0
    expect(mood_check_in).not_to be_valid
    expect(mood_check_in.errors[:mood_level]).to include("is not included in the list")
  end

  it "is invalid with mood level above 10" do
    mood_check_in.mood_level = 11
    expect(mood_check_in).not_to be_valid
    expect(mood_check_in.errors[:mood_level]).to include("is not included in the list")
  end

  context "mood_emoji" do
    it "returns 😢 for levels 1-2" do
      [ 1, 2 ].each do |level|
        mood_check_in.mood_level = level
        expect(mood_check_in.mood_emoji).to eq("😢")
      end
    end

    it "returns 😔 for levels 3-4" do
      [ 3, 4 ].each do |level|
        mood_check_in.mood_level = level
        expect(mood_check_in.mood_emoji).to eq("😔")
      end
    end

    it "returns 😐 for levels 5-6" do
      [ 5, 6 ].each do |level|
        mood_check_in.mood_level = level
        expect(mood_check_in.mood_emoji).to eq("😐")
      end
    end

    it "returns 😊 for levels 7-8" do
      [ 7, 8 ].each do |level|
        mood_check_in.mood_level = level
        expect(mood_check_in.mood_emoji).to eq("😊")
      end
    end

    it "returns 😄 for levels 9-10" do
      [ 9, 10 ].each do |level|
        mood_check_in.mood_level = level
        expect(mood_check_in.mood_emoji).to eq("😄")
      end
    end
  end

  context "mood_description" do
    it "returns 'Having a tough time' for levels 1-2" do
      [ 1, 2 ].each do |level|
        mood_check_in.mood_level = level
        expect(mood_check_in.mood_description).to eq("Having a tough time")
      end
    end

    it "returns 'Feeling low' for levels 3-4" do
      [ 3, 4 ].each do |level|
        mood_check_in.mood_level = level
        expect(mood_check_in.mood_description).to eq("Feeling low")
      end
    end

    it "returns 'Neutral' for levels 5-6" do
      [ 5, 6 ].each do |level|
        mood_check_in.mood_level = level
        expect(mood_check_in.mood_description).to eq("Neutral")
      end
    end

    it "returns 'Feeling good' for levels 7-8" do
      [ 7, 8 ].each do |level|
        mood_check_in.mood_level = level
        expect(mood_check_in.mood_description).to eq("Feeling good")
      end
    end

    it "returns 'Feeling amazing' for levels 9-10" do
      [ 9, 10 ].each do |level|
        mood_check_in.mood_level = level
        expect(mood_check_in.mood_description).to eq("Feeling amazing")
      end
    end
  end

  it "saves a valid mood check-in to the database" do
    mood_check_in.mood_level = 8
    mood_check_in.notes = "Great day!"

    expect { mood_check_in.save }.to change(MoodCheckIn, :count).by(1)

    saved = MoodCheckIn.last
    expect(saved.mood_level).to eq(8)
    expect(saved.notes).to eq("Great day!")
    expect(saved.created_at).not_to be_nil
  end

  it "does not save an invalid mood check-in" do
    mood_check_in.mood_level = 15

    expect { mood_check_in.save }.not_to change(MoodCheckIn, :count)
    expect(mood_check_in.errors[:mood_level]).to include("is not included in the list")
  end
end

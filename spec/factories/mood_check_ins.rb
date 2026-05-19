FactoryBot.define do
  factory :mood_check_in do
    mood_level { 8 }
    notes { "Feeling great today!" }

    trait :low_mood do
      mood_level { 2 }
      notes { "Having a tough day" }
    end

    trait :neutral do
      mood_level { 5 }
      notes { "Feeling okay" }
    end

    trait :high_mood do
      mood_level { 10 }
      notes { "Feeling amazing!" }
    end

    trait :yesterday do
      created_at { 1.day.ago }
    end

    trait :last_week do
      created_at { 1.week.ago }
    end

    trait :without_notes do
      notes { nil }
    end
  end
end

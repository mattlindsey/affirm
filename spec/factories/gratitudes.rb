FactoryBot.define do
  factory :gratitude do
    content { "I am grateful for the beautiful weather today." }

    trait :yesterday do
      created_at { 1.day.ago }
    end

    trait :last_week do
      created_at { 1.week.ago }
    end

    trait :with_emoji do
      content { "I am grateful for coffee ☕ and sunshine ☀️!" }
    end

    trait :long_content do
      content { "I am grateful for " + ("this amazing experience " * 50) }
    end
  end
end

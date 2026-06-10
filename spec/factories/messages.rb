FactoryBot.define do
  factory :message do
    association :conversation
    role { "user" }
    sequence(:content) { |n| "Message #{n}" }

    trait :assistant do
      role { "assistant" }
      sequence(:content) { |n| "Assistant reply #{n}" }
    end
  end
end

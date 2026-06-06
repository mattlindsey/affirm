FactoryBot.define do
  factory :setting do
    association :user
    name { nil }
    openai_api_key { nil }

    trait :with_openai_key do
      openai_api_key { "sk-test-#{SecureRandom.hex(16)}" }
    end
  end
end

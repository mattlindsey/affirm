FactoryBot.define do
  factory :conversation do
    association :user

    trait :positive_psychology do
      use_positive_psychology { true }
    end
  end
end

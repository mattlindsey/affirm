FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :google_only do
      password { nil }
      password_confirmation { nil }
      sequence(:google_uid) { |n| "google_uid_#{n}" }
    end
  end
end

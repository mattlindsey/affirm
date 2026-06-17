FactoryBot.define do
  factory :post do
    sequence(:title) { |n| "Post Title #{n}" }
    body { "This is **markdown** body content." }
    sequence(:slug) { |n| "post-slug-#{n}" }
    published_at { 1.day.ago }

    trait :unpublished do
      published_at { nil }
    end
  end
end

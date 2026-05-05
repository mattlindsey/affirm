FactoryBot.define do
  factory :reflection do
    association :mood_check_in
    content { "Today I reflected on my gratitude practice." }
  end
end

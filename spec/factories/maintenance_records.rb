FactoryBot.define do
  factory :maintenance_record do
    association :asset
    description { "Replaced hard drive" }
    performed_at { Time.current }
    cost { 250.00 }
  end
end

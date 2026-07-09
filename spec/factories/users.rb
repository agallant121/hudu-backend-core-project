FactoryBot.define do
  factory :user do
    name { "Tech Support" }
    sequence(:email) { |number| "user#{number}@example.com" }
  end
end

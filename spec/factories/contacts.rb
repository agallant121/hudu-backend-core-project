FactoryBot.define do
  factory :contact do
    association :company
    name { "John Smith" }
    sequence(:email) { |number| "contact#{number}@example.com" }
    role { Contact::PRIMARY_ROLE }
  end
end

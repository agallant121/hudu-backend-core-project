FactoryBot.define do
  factory :company do
    sequence(:name) { |number| "Company #{number}" }
    city { "Denver" }
    state { "CO" }
  end
end

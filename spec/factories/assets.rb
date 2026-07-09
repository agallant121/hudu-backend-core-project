FactoryBot.define do
  factory :asset do
    association :company
    sequence(:name) { |number| "ASSET-#{number}" }
    asset_type { "server" }
    sequence(:serial_number) { |number| "SN#{number}" }
    purchase_date { Date.current }
  end
end

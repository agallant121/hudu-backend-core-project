FactoryBot.define do
  factory :software_license do
    association :asset
    software_name { "Windows Server 2019" }
    license_key { "XXXXX-XXXXX-XXXXX" }
    expiration_date { 30.days.from_now.to_date }
  end
end

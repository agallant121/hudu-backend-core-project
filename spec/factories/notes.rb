FactoryBot.define do
  factory :note do
    association :asset
    association :author, factory: :user
    content { "Disk space running low on C: drive" }
  end
end

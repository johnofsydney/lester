FactoryBot.define do
  factory :person do
    sequence(:name) { |n| "Person #{n}" }
    aec_id { nil }
  end
end

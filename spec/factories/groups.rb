FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }
    aec_id { nil }
  end
end

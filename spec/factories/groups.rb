FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }

    transient do
      aec_id { nil }
    end

    after(:create) do |group, evaluator|
      group.aec_id = evaluator.aec_id if evaluator.aec_id.present?
    end
  end
end

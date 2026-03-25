FactoryBot.define do
  factory :person do
    sequence(:name) { |n| "Person #{n}" }

    transient do
      aec_id { nil }
    end

    after(:create) do |person, evaluator|
      person.aec_id = evaluator.aec_id if evaluator.aec_id.present?
    end
  end
end

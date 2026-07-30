FactoryBot.define do
  factory :membership do
    association :member, factory: :person
    association :group
  end
end

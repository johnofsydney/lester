require 'rails_helper'

RSpec.describe Group::RecordRow, type: :service do
  subject(:call_service) do
    described_class.new(group:, person:, title:, evidence:, start_date:, end_date:).call
  end

  let(:group) { FactoryBot.create(:group, name: 'Bathurst Regional Council') }
  let(:person) { FactoryBot.create(:person, name: 'Jane Smith') }
  let(:title) { nil }
  let(:evidence) { nil }
  let(:start_date) { nil }
  let(:end_date) { nil }

  describe '#call' do
    context 'when no membership exists yet' do
      it 'creates an open membership with the given start_date and evidence' do
        result = described_class.new(
          group:, person:, title: nil,
          evidence: 'NSW Electoral Commission 2024 declared results',
          start_date: Date.new(2024, 9, 14), end_date: nil
        ).call

        expect(result.start_date).to eq(Date.new(2024, 9, 14))
        expect(result.evidence).to eq('NSW Electoral Commission 2024 declared results')
        expect(result.end_date).to be_nil
      end

      it 'creates a Position when a title is given' do
        described_class.new(group:, person:, title: 'mayor').call

        membership = Membership.find_by(group:, member: person)
        expect(membership.positions.pluck(:title)).to eq(['Mayor'])
      end

      it 'does not create a Position when no title is given' do
        described_class.new(group:, person:).call

        membership = Membership.find_by(group:, member: person)
        expect(membership.positions).to be_empty
      end

      it 'gives the Position the same start_date and end_date as the Membership' do
        described_class.new(
          group:, person:, title: 'councillor',
          start_date: Date.new(2021, 12, 4), end_date: Date.new(2024, 9, 14)
        ).call

        membership = Membership.find_by(group:, member: person)
        position = membership.positions.sole

        expect(position.start_date).to eq(Date.new(2021, 12, 4))
        expect(position.end_date).to eq(Date.new(2024, 9, 14))
      end
    end

    context 'when an open membership already exists for this group and person' do
      let!(:existing_membership) do
        Membership.create!(group:, member: person, start_date: Date.new(2020, 1, 1), evidence: 'original evidence')
      end

      it 'reuses the existing open membership rather than creating a new one' do
        expect do
          described_class.new(group:, person:, start_date: Date.new(2024, 9, 14)).call
        end.not_to change(Membership, :count)
      end

      it 'does not overwrite an already-present start_date or evidence' do
        described_class.new(group:, person:, start_date: Date.new(2024, 9, 14), evidence: 'new evidence').call

        expect(existing_membership.reload.start_date).to eq(Date.new(2020, 1, 1))
        expect(existing_membership.reload.evidence).to eq('original evidence')
      end

      it 'sets end_date to close the membership' do
        described_class.new(group:, person:, end_date: Date.new(2024, 9, 14), evidence: 'not returned').call

        expect(existing_membership.reload.end_date).to eq(Date.new(2024, 9, 14))
      end

      it 'keeps an existing Position\'s dates in sync with the Membership on a later call' do
        described_class.new(group:, person:, title: 'councillor').call

        described_class.new(group:, person:, title: 'councillor', end_date: Date.new(2024, 9, 14)).call

        position = existing_membership.reload.positions.sole
        expect(position.start_date).to eq(Date.new(2020, 1, 1))
        expect(position.end_date).to eq(Date.new(2024, 9, 14))
      end
    end

    context 'when a closed membership already exists for this group and person' do
      let!(:closed_membership) do
        Membership.create!(group:, member: person, start_date: Date.new(2016, 1, 1), end_date: Date.new(2020, 1, 1))
      end

      it 'creates a new membership row rather than reopening the closed one' do
        expect do
          described_class.new(group:, person:, start_date: Date.new(2024, 9, 14)).call
        end.to change(Membership, :count).by(1)

        expect(closed_membership.reload.end_date).to eq(Date.new(2020, 1, 1))
      end
    end
  end
end

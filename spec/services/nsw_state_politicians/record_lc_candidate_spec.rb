require 'rails_helper'

RSpec.describe NswStatePoliticians::RecordLcCandidate, type: :service do
  let(:nsw_parliament) { FactoryBot.create(:group, name: 'nsw parliament') }
  let(:base_args) do
    {
      event_id: 'SG2301',
      name: 'HOUSSOS Courtney',
      party: 'LABOR',
      elected: true,
      group_letter: 'D',
      elected_at_count: '1',
      source_url: 'https://pastvtr.elections.nsw.gov.au/SG2301/LC/state/candidates_elected'
    }
  end

  before do
    allow(Group).to receive(:nsw_parliament).and_return(nsw_parliament)
    FactoryBot.create(:group, name: Group::NAMES.labor.nsw)
  end

  describe '#call' do
    context 'for a winner' do
      it 'creates the Person with the name reformatted (surname-first swap)' do
        described_class.call(**base_args)

        expect(Person.exists?(name: 'courtney houssos')).to be(true)
      end

      it 'creates an undated Membership + Position in the NSW Parliament Group' do
        described_class.call(**base_args)

        person = Person.find_by(name: 'courtney houssos')
        membership = Membership.find_by(group: nsw_parliament, member: person)

        expect(membership.start_date).to be_nil
        expect(membership.end_date).to be_nil
        expect(membership.evidence).to include('NSW Electoral Commission')
        expect(membership.positions.pluck(:title)).to eq(['Member of the Legislative Council'])
      end

      it 'creates an undated party Membership' do
        described_class.call(**base_args)

        person = Person.find_by(name: 'courtney houssos')
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.labor.nsw), member: person)).to be(true)
      end

      it 'appends a raw observation to state_election_data, with electorate fixed to "statewide"' do
        described_class.call(**base_args)

        person = Person.find_by(name: 'courtney houssos')
        observation = person.state_election_data.first

        expect(observation['state']).to eq('nsw')
        expect(observation['event_id']).to eq('SG2301')
        expect(observation['house']).to eq('LC')
        expect(observation['electorate']).to eq('statewide')
        expect(observation['group_letter']).to eq('D')
        expect(observation['elected']).to be(true)
      end

      context 'when the winner\'s party has no existing Group' do
        let(:args) { base_args.merge(party: 'THE GREENS', group_letter: 'R') }

        it 'creates the party Group (as a plain Group, not a Tag) rather than skipping the person' do
          expect do
            described_class.call(**args)
          end.to change(Group, :count).by(1) # the new party Group

          party_group = Group.find_by(name: Group::NAMES.greens.nsw)
          expect(party_group.type).to be_nil
        end
      end
    end

    context 'for an unsuccessful candidate whose group\'s party already has a Group' do
      let(:args) { base_args.merge(name: 'SHELTON Lyle', party: 'THE GREENS', elected: false, group_letter: 'R') }

      before { FactoryBot.create(:group, name: Group::NAMES.greens.nsw) }

      it 'is ingested, with the party Membership but no NSW Parliament Membership' do
        described_class.call(**args)

        person = Person.find_by(name: 'lyle shelton')
        expect(person).to be_present
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.greens.nsw), member: person)).to be(true)
        expect(Membership.exists?(group: nsw_parliament, member: person)).to be(false)
      end
    end

    context 'for an unsuccessful candidate whose group has no declared party name (an ungrouped independent)' do
      let(:args) { base_args.merge(name: 'SOME Independent', party: nil, elected: false, group_letter: 'A') }

      it 'is not ingested, and returns nil' do
        expect(described_class.call(**args)).to be_nil
        expect(Person.exists?(name: 'independent some')).to be(false)
      end
    end

    context 'for an unsuccessful candidate whose party has no existing Group (a micro-party)' do
      let(:args) { base_args.merge(name: 'SOME Candidate', party: 'SUSTAINABLE AUSTRALIA PARTY - STOP OVERDEVELOPMENT / CORRUPTION', elected: false, group_letter: 'S') }

      it 'is not ingested' do
        expect(described_class.call(**args)).to be_nil
        expect(Person.exists?(name: 'candidate some')).to be(false)
      end
    end

    context 'for a joint-ticket party (first-named party wins)' do
      let(:args) { base_args.merge(name: 'MACLAREN-JONES Natasha', party: 'LIBERAL / THE NATIONALS', group_letter: 'I') }

      before { FactoryBot.create(:group, name: Group::NAMES.liberals.nsw) }

      it 'links the party Membership to the first-named party' do
        described_class.call(**args)

        person = Person.find_by(name: 'natasha maclaren-jones')
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.liberals.nsw), member: person)).to be(true)
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.nationals.nsw), member: person)).to be(false)
      end
    end
  end
end

require 'rails_helper'

RSpec.describe NswStatePoliticians::RecordLaCandidate, type: :service do
  let(:nsw_parliament) { FactoryBot.create(:group, name: 'nsw parliament') }
  let(:base_args) do
    {
      event_id: 'SG2301',
      electorate: 'auburn',
      name: 'VOLTZ Lynda',
      party: 'Australian Labor Party (NSW Branch)',
      elected: true,
      source_url: 'https://pastvtr.elections.nsw.gov.au/SG2301/LA/state/elected'
    }
  end

  before do
    allow(Group).to receive(:nsw_parliament).and_return(nsw_parliament)
    # Real party Groups in this app are plain Groups (type: nil), not Tags -- matching that
    # convention here is load-bearing: an earlier bug scoped the winner-path lookup to type:
    # 'Tag' and silently created duplicate Groups instead of finding these.
    FactoryBot.create(:group, name: Group::NAMES.labor.nsw)
  end

  describe '#call' do
    context 'for a winner' do
      it 'creates the Person with the name reformatted (surname-first swap + honorific cleanup)' do
        described_class.call(**base_args)

        expect(Person.exists?(name: 'lynda voltz')).to be(true)
      end

      it 'creates an undated Membership + Position in the NSW Parliament Group' do
        described_class.call(**base_args)

        person = Person.find_by(name: 'lynda voltz')
        membership = Membership.find_by(group: nsw_parliament, member: person)

        expect(membership.start_date).to be_nil
        expect(membership.end_date).to be_nil
        expect(membership.evidence).to include('NSW Electoral Commission')
        expect(membership.positions.pluck(:title)).to eq(['Member of the Legislative Assembly'])
      end

      it 'creates an undated party Membership' do
        described_class.call(**base_args)

        person = Person.find_by(name: 'lynda voltz')
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.labor.nsw), member: person)).to be(true)
      end

      it 'appends a raw observation to state_election_data' do
        described_class.call(**base_args)

        person = Person.find_by(name: 'lynda voltz')
        observation = person.state_election_data.first

        expect(observation['state']).to eq('nsw')
        expect(observation['event_id']).to eq('SG2301')
        expect(observation['house']).to eq('LA')
        expect(observation['electorate']).to eq('auburn')
        expect(observation['elected']).to be(true)
      end

      context 'when the winner\'s party has no existing Group' do
        let(:args) { base_args.merge(party: 'The Greens NSW') }

        it 'creates the party Group (as a plain Group, not a Tag) rather than skipping the person' do
          expect do
            described_class.call(**args)
          end.to change(Group, :count).by(1) # the new party Group

          party_group = Group.find_by(name: Group::NAMES.greens.nsw)
          expect(party_group.type).to be_nil

          person = Person.find_by(name: 'lynda voltz')
          expect(Membership.exists?(group: party_group, member: person)).to be(true)
        end
      end
    end

    context 'for an unsuccessful candidate whose party already has a Group' do
      let(:args) { base_args.merge(name: 'ASGARI Masoomeh', party: 'The Greens NSW', elected: false) }

      before { FactoryBot.create(:group, name: Group::NAMES.greens.nsw) }

      it 'is ingested' do
        described_class.call(**args)

        expect(Person.exists?(name: 'masoomeh asgari')).to be(true)
      end

      it 'gets the party Membership, but NOT an NSW Parliament Membership -- they never won a seat' do
        described_class.call(**args)

        person = Person.find_by(name: 'masoomeh asgari')
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.greens.nsw), member: person)).to be(true)
        expect(Membership.exists?(group: nsw_parliament, member: person)).to be(false)
      end
    end

    # Regression case: Adam Guise, an ingested-but-unsuccessful Greens candidate who lost Lismore
    # to Janelle Saffin (SG2301) -- an earlier version of #call created the NSW Parliament
    # Membership unconditionally, so a real losing candidate showed up as a sitting MLA. The
    # assertion pairing here (has the party Membership; does NOT have the Parliament one) is the
    # deliberate shape -- a test that only checked "gets ingested" would have passed against that
    # bug, since Guise WAS correctly ingested; it's what he was ingested *into* that was wrong.
    context 'for an ingested unsuccessful candidate (regression: Adam Guise, lost Lismore to Janelle Saffin)' do
      let(:args) { base_args.merge(name: 'GUISE Adam', party: 'The Greens NSW', elected: false, electorate: 'lismore', source_url: 'https://pastvtr.elections.nsw.gov.au/SG2301/LA/lismore/cc/fp_summary') }

      before { FactoryBot.create(:group, name: Group::NAMES.greens.nsw) }

      it 'has the party Membership but not a seat in NSW Parliament' do
        described_class.call(**args)

        person = Person.find_by(name: 'adam guise')
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.greens.nsw), member: person)).to be(true)
        expect(Membership.exists?(group: nsw_parliament, member: person)).to be(false)
      end
    end

    context 'for an unsuccessful candidate whose party has no existing Group (e.g. a micro-party)' do
      let(:args) { base_args.merge(name: 'GOED Shelley', party: 'Sustainable Australia Party - Stop Overdevelopment / Corruption', elected: false) }

      it 'is not ingested, and returns nil' do
        expect(described_class.call(**args)).to be_nil
        expect(Person.exists?(name: 'shelley goed')).to be(false)
      end
    end

    context 'for an unsuccessful independent candidate' do
      let(:args) { base_args.merge(name: 'DAOUD Jamal', party: '', elected: false) }

      it 'is not ingested' do
        expect(described_class.call(**args)).to be_nil
        expect(Person.exists?(name: 'jamal daoud')).to be(false)
      end
    end

    context 'for a joint-ticket party (first-named party wins)' do
      let(:args) { base_args.merge(party: 'LIBERAL / THE NATIONALS') }

      before { FactoryBot.create(:group, name: Group::NAMES.liberals.nsw) }

      it 'links the party Membership to the first-named party' do
        described_class.call(**args)

        person = Person.find_by(name: 'lynda voltz')
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.liberals.nsw), member: person)).to be(true)
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.nationals.nsw), member: person)).to be(false)
      end
    end
  end
end

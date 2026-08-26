require 'rails_helper'

RSpec.describe Councils::Nsw::ImportCouncilResultRowJob, type: :job do
  describe '#perform' do
    let(:council_name) { 'Federation Council' }
    let(:council_slug) { 'federation' }
    let(:results_url) { "https://pastvtr.elections.nsw.gov.au/#{Councils::Nsw::Elections.latest[:id]}/#{council_slug}/results" }
    let(:expected_url) { "https://pastvtr.elections.nsw.gov.au/#{Councils::Nsw::Elections.latest[:id]}/#{council_slug}/councillor" }
    let(:results_page) { Rails.root.join('spec/fixtures/councils/nsw/results_single.html').read }

    before do
      FactoryBot.create(:group, name: Group::NAMES.labor.nsw, type: 'Tag')
      FactoryBot.create(:group, name: Group::NAMES.greens.nsw, type: 'Tag')
      # Group.government_department_tag and Group.local_councils_tag are hardcoded to
      # production-only IDs (app/models/group.rb) -- stub them so they don't blow up against the
      # test DB.
      allow(Group).to receive_messages(
        government_department_tag: FactoryBot.create(:group, name: 'government department tag', type: 'Tag'),
        local_councils_tag: FactoryBot.create(:group, name: 'australian local councils', type: 'Tag')
      )

      allow(Councils::PageDownloader).to receive(:call).with(results_url).and_return(results_page)
      allow(Councils::PageDownloader).to receive(:call).with(expected_url).and_return(page)
    end

    context 'when the council has declared results' do
      let(:page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_declared.html').read }

      it 'creates the council as a Group tagged into Australian Local Councils' do
        described_class.new.perform(council_name, council_slug)

        council = Group.find_by(name: council_name)
        expect(council).to be_present
        expect(Membership.exists?(group: Group.local_councils_tag, member: council)).to be(true)
      end

      it 'records each declared candidate as a Person with an undated Councillor Membership' do
        described_class.new.perform(council_name, council_slug)

        council = Group.find_by(name: council_name)
        person = Person.find_by(name: 'derek schoen')
        membership = Membership.find_by(group: council, member: person)

        expect(membership.start_date).to be_nil
        expect(membership.end_date).to be_nil
        expect(membership.evidence).to include('NSW Electoral Commission')
        expect(membership.positions.pluck(:title)).to eq(['Councillor'])
        expect(membership.positions.first.start_date).to be_nil
        expect(membership.positions.first.end_date).to be_nil
      end

      it 'appends a raw observation to the Person\'s council_election_data' do
        described_class.new.perform(council_name, council_slug)

        person = Person.find_by(name: 'derek schoen')
        observation = person.council_election_data.first

        expect(observation['state']).to eq('nsw')
        expect(observation['council_name']).to eq('federation council')
        expect(observation['council_slug']).to eq('federation')
        expect(observation['cycle']).to eq(Councils::Nsw::Elections.latest[:id])
        expect(observation['declared_date']).to eq('2024-10-01')
        expect(observation['party']).to eq('Independent')
      end

      it 'links a candidate to their party tag when the party is shown and maps to a known party' do
        described_class.new.perform(council_name, council_slug)

        labor_person = Person.find_by(name: 'darren cameron')
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.labor.nsw), member: labor_person)).to be(true)

        greens_person = Person.find_by(name: 'geoff hudson')
        expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.greens.nsw), member: greens_person)).to be(true)
      end

      it 'does not create a party membership for an Independent or blank party' do
        described_class.new.perform(council_name, council_slug)

        independent_person = Person.find_by(name: 'derek schoen')
        no_party_person = Person.find_by(name: 'andrew kennedy')

        expect(Membership.where(member: independent_person).where.not(group: Group.find_by(name: council_name)).count).to eq(0)
        expect(Membership.where(member: no_party_person).where.not(group: Group.find_by(name: council_name)).count).to eq(0)
      end

      context 'when a candidate was already an open member of the council (re-elected)' do
        let!(:council) { FactoryBot.create(:group, name: council_name) }
        let!(:returning_person) { FactoryBot.create(:person, name: 'Derek Schoen') }
        let!(:returning_membership) do
          Membership.create!(group: council, member: returning_person, evidence: 'original evidence')
        end

        it 'reuses the existing open membership rather than creating a new one' do
          # +1 council->tag membership, +1 Cameron/council, +1 Cameron/Labor, +1 Hudson/council,
          # +1 Hudson/Greens, +1 Kennedy/council. Schoen (Independent, already an open member)
          # contributes 0 new memberships.
          expect do
            described_class.new.perform(council_name, council_slug)
          end.to change(Membership, :count).by(6)

          expect(Membership.where(group: council, member: returning_person).count).to eq(1)
          expect(returning_membership.reload.evidence).to eq('original evidence')
        end
      end
    end

    context 'when backfilling a non-latest election cycle' do
      let(:backfill_election) { Councils::Nsw::Elections::ALL.first }
      let(:results_url) { "https://pastvtr.elections.nsw.gov.au/#{backfill_election[:id]}/#{council_slug}/results" }
      let(:expected_url) { "https://pastvtr.elections.nsw.gov.au/#{backfill_election[:id]}/#{council_slug}/councillor" }
      let(:page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_declared.html').read }

      it 'does not touch an existing open membership unrelated to this cycle\'s candidates' do
        council = FactoryBot.create(:group, name: council_name)
        unrelated_person = FactoryBot.create(:person, name: 'Unrelated Councillor')
        unrelated_membership = Membership.create!(group: council, member: unrelated_person)

        described_class.new.perform(council_name, council_slug, backfill_election[:id])

        expect(unrelated_membership.reload.end_date).to be_nil
      end

      it 'creates an undated Membership for a backfilled candidate' do
        described_class.new.perform(council_name, council_slug, backfill_election[:id])

        council = Group.find_by(name: council_name)
        person = Person.find_by(name: 'derek schoen')
        membership = Membership.find_by(group: council, member: person)

        expect(membership.start_date).to be_nil
        expect(membership.end_date).to be_nil
      end

      it 'reuses the existing open membership for a candidate who continued into a later cycle' do
        council = FactoryBot.create(:group, name: council_name)
        continuing_person = FactoryBot.create(:person, name: 'Derek Schoen')
        continuing_membership = Membership.create!(group: council, member: continuing_person)

        described_class.new.perform(council_name, council_slug, backfill_election[:id])

        expect(continuing_membership.reload.end_date).to be_nil
        expect(Membership.where(group: council, member: continuing_person).count).to eq(1)
      end

      it 'appends a raw observation tagged with the backfill cycle' do
        described_class.new.perform(council_name, council_slug, backfill_election[:id])

        person = Person.find_by(name: 'derek schoen')
        observation = person.council_election_data.first

        expect(observation['cycle']).to eq(backfill_election[:id])
      end
    end

    context 'when the council was under administration for this cycle (no election held)' do
      let(:results_page) { Rails.root.join('spec/fixtures/councils/nsw/results_in_administration.html').read }
      let(:page) { nil } # no councillor contest page exists for a council in administration

      it 'does not raise, and does not create the council Group, any Person, or any Membership' do
        expect { described_class.new.perform(council_name, council_slug) }.not_to raise_error

        expect(Group.find_by(name: council_name)).to be_nil
        expect(Person.count).to eq(0)
        expect(Membership.count).to eq(0)
      end
    end

    context 'when the council runs its own election, outside NSWEC' do
      let(:results_page) { Rails.root.join('spec/fixtures/councils/nsw/results_council_run_election.html').read }
      let(:page) { nil } # NSWEC never has a councillor contest page for these councils

      it 'does not raise, and does not create the council Group, any Person, or any Membership' do
        expect { described_class.new.perform(council_name, council_slug) }.not_to raise_error

        expect(Group.find_by(name: council_name)).to be_nil
        expect(Person.count).to eq(0)
        expect(Membership.count).to eq(0)
      end
    end

    context 'when the council has not yet declared results' do
      let(:page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_not_declared.html').read }

      it 'does not create the council Group, any Person, or any Membership' do
        described_class.new.perform(council_name, council_slug)

        expect(Group.find_by(name: council_name)).to be_nil
        expect(Person.count).to eq(0)
        expect(Membership.count).to eq(0)
      end
    end

    context 'when the results page fails to download' do
      let(:results_page) { nil }
      let(:page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_declared.html').read }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform(council_name, council_slug) }.to raise_error(RuntimeError, /Failed to download NSW council results page/)
        expect(ApiLog.last.endpoint).to eq(results_url)
      end
    end

    context 'when the councillor contest page fails to download' do
      let(:page) { nil }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform(council_name, council_slug) }.to raise_error(RuntimeError, /Failed to download NSW councillor results/)
        expect(ApiLog.last.endpoint).to eq(expected_url)
      end
    end

    context 'when the council is divided into wards' do
      let(:council_name) { 'City of Blacktown' }
      let(:council_slug) { 'blacktown' }
      let(:page) { nil } # no flat "councillor" page exists for a ward council
      let(:results_page) { Rails.root.join('spec/fixtures/councils/nsw/results_wards.html').read }
      let(:ward_1_url) { "https://pastvtr.elections.nsw.gov.au/#{Councils::Nsw::Elections.latest[:id]}/#{council_slug}/ward-1/councillor" }
      let(:ward_2_url) { "https://pastvtr.elections.nsw.gov.au/#{Councils::Nsw::Elections.latest[:id]}/#{council_slug}/ward-2/councillor" }
      let(:ward_1_page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_declared.html').read }
      let(:ward_2_page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_declared.html').read }

      before do
        allow(Councils::PageDownloader).to receive(:call).with(ward_1_url).and_return(ward_1_page)
        allow(Councils::PageDownloader).to receive(:call).with(ward_2_url).and_return(ward_2_page)
      end

      it 'records candidates from every ward under the same council Group' do
        described_class.new.perform(council_name, council_slug)

        council = Group.find_by(name: council_name)
        person = Person.find_by(name: 'derek schoen')
        expect(Membership.exists?(group: council, member: person)).to be(true)
      end

      context 'when only some wards have declared' do
        let(:ward_2_page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_not_declared.html').read }
        let!(:council) { FactoryBot.create(:group, name: council_name) }
        let!(:ward_2_incumbent) { FactoryBot.create(:person, name: 'Ward Two Incumbent') }
        let!(:ward_2_membership) do
          Membership.create!(group: council, member: ward_2_incumbent)
        end

        it 'still records the declared ward, leaving the undeclared ward\'s existing membership untouched' do
          described_class.new.perform(council_name, council_slug)

          expect(Person.find_by(name: 'derek schoen')).to be_present
          expect(ward_2_membership.reload.end_date).to be_nil
        end
      end
    end

    context 'when the council also has a separate mayoral contest' do
      let(:council_name) { 'Hornsby Shire Council' }
      let(:council_slug) { 'hornsby' }
      let(:page) { nil } # no flat "councillor" page exists for a ward council
      let(:results_page) { Rails.root.join('spec/fixtures/councils/nsw/results_with_mayor.html').read }
      let(:ward_a_url) { "https://pastvtr.elections.nsw.gov.au/#{Councils::Nsw::Elections.latest[:id]}/#{council_slug}/ward-a/councillor" }
      let(:ward_b_url) { "https://pastvtr.elections.nsw.gov.au/#{Councils::Nsw::Elections.latest[:id]}/#{council_slug}/ward-b/councillor" }
      let(:mayoral_url) { "https://pastvtr.elections.nsw.gov.au/#{Councils::Nsw::Elections.latest[:id]}/#{council_slug}/mayoral" }
      let(:ward_page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_declared.html').read }
      let(:mayoral_page) { Rails.root.join('spec/fixtures/councils/nsw/mayor_declared.html').read }

      before do
        allow(Councils::PageDownloader).to receive(:call).with(ward_a_url).and_return(ward_page)
        allow(Councils::PageDownloader).to receive(:call).with(ward_b_url).and_return(ward_page)
        allow(Councils::PageDownloader).to receive(:call).with(mayoral_url).and_return(mayoral_page)
      end

      it 'records the mayoral candidate as a Person with a Position titled Mayor, distinct from Councillor' do
        described_class.new.perform(council_name, council_slug)

        council = Group.find_by(name: council_name)
        councillor = Person.find_by(name: 'derek schoen')
        mayor = Person.find_by(name: 'philip ruddock')

        expect(Membership.find_by(group: council, member: councillor).positions.pluck(:title)).to eq(['Councillor'])
        expect(Membership.find_by(group: council, member: mayor).positions.pluck(:title)).to eq(['Mayor'])
      end
    end
  end
end

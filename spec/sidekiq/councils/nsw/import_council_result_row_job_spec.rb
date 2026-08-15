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
      # Group.government_department_tag is hardcoded to a production-only ID (app/models/group.rb) --
      # stub it so Tag::AddGroupToTag#valid? doesn't blow up against the test DB.
      allow(Group).to receive(:government_department_tag).and_return(FactoryBot.create(:group, name: 'government department tag', type: 'Tag'))

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

      it 'records each declared candidate as a Person with a Councillor Membership dated to the declaration' do
        described_class.new.perform(council_name, council_slug)

        council = Group.find_by(name: council_name)
        person = Person.find_by(name: 'derek schoen')
        membership = Membership.find_by(group: council, member: person)

        expect(membership.start_date).to eq(Date.new(2024, 10, 1))
        expect(membership.evidence).to include('NSW Electoral Commission')
        expect(membership.positions.pluck(:title)).to eq(['Councillor'])
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

      context 'when a councillor who was not re-elected currently has an open membership' do
        let!(:council) { FactoryBot.create(:group, name: council_name) }
        let!(:departing_person) { FactoryBot.create(:person, name: 'Old Councillor') }
        let!(:departing_membership) do
          Membership.create!(group: council, member: departing_person, start_date: Date.new(2016, 1, 1))
        end

        it 'closes their membership with the declared date' do
          described_class.new.perform(council_name, council_slug)

          expect(departing_membership.reload.end_date).to eq(Date.new(2024, 10, 1))
          expect(departing_membership.reload.evidence).to include('Not returned')
        end
      end

      context 'when a candidate was already an open member of the council (re-elected)' do
        let!(:council) { FactoryBot.create(:group, name: council_name) }
        let!(:returning_person) { FactoryBot.create(:person, name: 'Derek Schoen') }
        let!(:returning_membership) do
          Membership.create!(group: council, member: returning_person, start_date: Date.new(2020, 1, 1), evidence: 'original evidence')
        end

        it 'reuses the existing open membership without overwriting its start_date or evidence' do
          # +1 council->tag membership, +1 Cameron/council, +1 Cameron/Labor, +1 Hudson/council,
          # +1 Hudson/Greens, +1 Kennedy/council. Schoen (Independent, already an open member)
          # contributes 0 new memberships.
          expect do
            described_class.new.perform(council_name, council_slug)
          end.to change(Membership, :count).by(6)

          expect(Membership.where(group: council, member: returning_person).count).to eq(1)

          expect(returning_membership.reload.start_date).to eq(Date.new(2020, 1, 1))
          expect(returning_membership.reload.evidence).to eq('original evidence')
          expect(returning_membership.reload.end_date).to be_nil
        end
      end
    end

    context 'when backfilling a non-latest election cycle' do
      let(:backfill_election) { Councils::Nsw::Elections::ALL.first }
      let(:results_url) { "https://pastvtr.elections.nsw.gov.au/#{backfill_election[:id]}/#{council_slug}/results" }
      let(:expected_url) { "https://pastvtr.elections.nsw.gov.au/#{backfill_election[:id]}/#{council_slug}/councillor" }
      let(:page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_declared.html').read }

      it 'does not close out an existing open membership that is unrelated to this cycle\'s candidates' do
        council = FactoryBot.create(:group, name: council_name)
        unrelated_person = FactoryBot.create(:person, name: 'Unrelated Councillor')
        unrelated_membership = Membership.create!(group: council, member: unrelated_person, start_date: Date.new(2016, 1, 1))

        described_class.new.perform(council_name, council_slug, backfill_election[:id])

        expect(unrelated_membership.reload.end_date).to be_nil
      end

      it 'closes out a backfilled candidate\'s new membership using the next cycle\'s election_date, since they have no open membership in the latest cycle' do
        described_class.new.perform(council_name, council_slug, backfill_election[:id])

        council = Group.find_by(name: council_name)
        person = Person.find_by(name: 'derek schoen')
        membership = Membership.find_by(group: council, member: person)

        expect(membership.start_date).to eq(Date.new(2024, 10, 1))
        expect(membership.end_date).to eq(Councils::Nsw::Elections.next(backfill_election[:id])[:election_date])
      end

      it 'leaves a candidate\'s existing open membership untouched when they continued into a later cycle' do
        council = FactoryBot.create(:group, name: council_name)
        continuing_person = FactoryBot.create(:person, name: 'Derek Schoen')
        continuing_membership = Membership.create!(group: council, member: continuing_person, start_date: Date.new(2024, 10, 1))

        described_class.new.perform(council_name, council_slug, backfill_election[:id])

        expect(continuing_membership.reload.start_date).to eq(Date.new(2024, 10, 1))
        expect(continuing_membership.reload.end_date).to be_nil
        expect(Membership.where(group: council, member: continuing_person).count).to eq(1)
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
          Membership.create!(group: council, member: ward_2_incumbent, start_date: Date.new(2016, 1, 1))
        end

        it 'still records the declared ward but does not close out members of the undeclared ward' do
          described_class.new.perform(council_name, council_slug)

          expect(Person.find_by(name: 'derek schoen')).to be_present
          expect(ward_2_membership.reload.end_date).to be_nil
        end
      end
    end
  end
end

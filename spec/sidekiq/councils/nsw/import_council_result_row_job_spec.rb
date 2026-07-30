require 'rails_helper'

RSpec.describe Councils::Nsw::ImportCouncilResultRowJob, type: :job do
  describe '#perform' do
    let(:council_name) { 'Federation Council' }
    let(:council_slug) { 'federation' }
    let(:expected_url) { "https://pastvtr.elections.nsw.gov.au/#{described_class::ELECTION_ID}/#{council_slug}/councillor" }

    before do
      FactoryBot.create(:group, name: Group::NAMES.labor.nsw, type: 'Tag')
      FactoryBot.create(:group, name: Group::NAMES.greens.nsw, type: 'Tag')
      # Group.government_department_tag is hardcoded to a production-only ID (app/models/group.rb) --
      # stub it so Tag::AddGroupToTag#valid? doesn't blow up against the test DB.
      allow(Group).to receive(:government_department_tag).and_return(FactoryBot.create(:group, name: 'government department tag', type: 'Tag'))

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

    context 'when the council has not yet declared results' do
      let(:page) { Rails.root.join('spec/fixtures/councils/nsw/councillor_not_declared.html').read }

      it 'does not create the council Group, any Person, or any Membership' do
        described_class.new.perform(council_name, council_slug)

        expect(Group.find_by(name: council_name)).to be_nil
        expect(Person.count).to eq(0)
        expect(Membership.count).to eq(0)
      end
    end

    context 'when the page fails to download' do
      let(:page) { nil }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform(council_name, council_slug) }.to raise_error(RuntimeError, /Failed to download/)
        expect(ApiLog.last.endpoint).to eq(expected_url)
      end
    end
  end
end

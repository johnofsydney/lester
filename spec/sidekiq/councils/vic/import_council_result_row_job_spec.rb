require 'rails_helper'

RSpec.describe Councils::Vic::ImportCouncilResultRowJob, type: :job do
  describe '#perform' do
    let(:council_name) { 'Alpine Shire Council' }
    let(:council_slug) { 'alpine-shire-council' }
    let(:expected_url) { "https://www.vec.vic.gov.au/results/council-election-results/#{described_class::ELECTION_YEAR}-council-election-results/#{council_slug}" }

    before do
      # Group.government_department_tag is hardcoded to a production-only ID (app/models/group.rb) --
      # stub it so Tag::AddGroupToTag#valid? doesn't blow up against the test DB.
      allow(Group).to receive(:government_department_tag).and_return(FactoryBot.create(:group, name: 'government department tag', type: 'Tag'))

      allow(Councils::PageDownloader).to receive(:call).with(expected_url).and_return(page)
    end

    context 'when the council has declared results' do
      let(:page) { Rails.root.join('spec/fixtures/councils/vic/councillor_declared.html').read }

      it 'creates the council as a Group tagged into Australian Local Councils' do
        described_class.new.perform(council_name, council_slug)

        council = Group.find_by(name: council_name)
        expect(council).to be_present
        expect(Membership.exists?(group: Group.local_councils_tag, member: council)).to be(true)
      end

      it 'records each elected candidate as a Person with a Councillor Membership dated to the last-updated date' do
        described_class.new.perform(council_name, council_slug)

        council = Group.find_by(name: council_name)
        person = Person.find_by(name: 'sarah nicholas')
        membership = Membership.find_by(group: council, member: person)

        expect(membership.start_date).to eq(Date.new(2024, 11, 22))
        expect(membership.evidence).to include('Victorian Electoral Commission')
        expect(membership.positions.pluck(:title)).to eq(['Councillor'])
      end

      it 'does not record any party membership' do
        described_class.new.perform(council_name, council_slug)

        person = Person.find_by(name: 'sarah nicholas')
        council = Group.find_by(name: council_name)

        expect(Membership.where(member: person).where.not(group: council).count).to eq(0)
      end

      context 'when a councillor who was not re-elected currently has an open membership' do
        let!(:council) { FactoryBot.create(:group, name: council_name) }
        let!(:departing_person) { FactoryBot.create(:person, name: 'Old Councillor') }
        let!(:departing_membership) do
          Membership.create!(group: council, member: departing_person, start_date: Date.new(2016, 1, 1))
        end

        it 'closes their membership with the declared date' do
          described_class.new.perform(council_name, council_slug)

          expect(departing_membership.reload.end_date).to eq(Date.new(2024, 11, 22))
          expect(departing_membership.reload.evidence).to include('Not returned')
        end
      end

      context 'when a candidate was already an open member of the council (re-elected)' do
        let!(:council) { FactoryBot.create(:group, name: council_name) }
        let!(:returning_person) { FactoryBot.create(:person, name: 'Sarah Nicholas') }
        let!(:returning_membership) do
          Membership.create!(group: council, member: returning_person, start_date: Date.new(2020, 1, 1), evidence: 'original evidence')
        end

        it 'reuses the existing open membership without overwriting its start_date or evidence' do
          described_class.new.perform(council_name, council_slug)

          expect(Membership.where(group: council, member: returning_person).count).to eq(1)
          expect(returning_membership.reload.start_date).to eq(Date.new(2020, 1, 1))
          expect(returning_membership.reload.evidence).to eq('original evidence')
          expect(returning_membership.reload.end_date).to be_nil
        end
      end
    end

    context 'when the council has not yet declared results' do
      let(:page) { Rails.root.join('spec/fixtures/councils/vic/councillor_not_declared.html').read }

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

    context 'when the council is divided into wards' do
      let(:council_name) { 'Casey City Council' }
      let(:council_slug) { 'casey-city-council' }
      let(:page) { Rails.root.join('spec/fixtures/councils/vic/councillor_declared_wards.html').read }

      it 'records candidates from every ward under the same council Group' do
        described_class.new.perform(council_name, council_slug)

        council = Group.find_by(name: council_name)
        expect(Person.find_by(name: 'scott william dowling')).to be_present
        expect(Person.find_by(name: 'damien nguyen')).to be_present
        expect(Membership.where(group: council, member_type: 'Person').count).to eq(2)
      end
    end
  end
end

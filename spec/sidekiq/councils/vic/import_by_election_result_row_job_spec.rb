require 'rails_helper'

RSpec.describe Councils::Vic::ImportByElectionResultRowJob, type: :job do
  describe '#perform' do
    let(:timeline_url) { Councils::Vic::IngestByElectionResultsJob::TIMELINE_URL }
    let(:url) { "#{timeline_url}/#{slug}" }

    before do
      allow(Group).to receive_messages(
        government_department_tag: FactoryBot.create(:group, name: 'government department tag', type: 'Tag'),
        local_councils_tag: FactoryBot.create(:group, name: 'australian local councils', type: 'Tag')
      )

      allow(Councils::PageDownloader).to receive(:call).with(url).and_return(page)
    end

    context 'for a by-election' do
      let(:slug) { 'maroondah-council-wonga-ward-by-election' }
      let(:kind) { 'by_election' }
      let(:council_description) { 'Maroondah City Council, Wonga Ward' }
      let(:page) { Rails.root.join('spec/fixtures/councils/vic/councillor_declared.html').read }

      it 'creates the council (without the ward suffix) as a Group tagged into Australian Local Councils' do
        described_class.new.perform(slug, kind, council_description)

        council = Group.find_by(name: 'Maroondah City Council')
        expect(council).to be_present
        expect(Membership.exists?(group: Group.local_councils_tag, member: council)).to be(true)
      end

      it 'records each elected candidate as a Person with an undated Councillor Membership' do
        described_class.new.perform(slug, kind, council_description)

        council = Group.find_by(name: 'Maroondah City Council')
        person = Person.find_by(name: 'sarah nicholas')
        membership = Membership.find_by(group: council, member: person)

        expect(membership.start_date).to be_nil
        expect(membership.evidence).to include('Victorian Electoral Commission by-election declared results')
      end

      it 'appends a raw observation to the council_election_data, keyed by the event slug' do
        described_class.new.perform(slug, kind, council_description)

        person = Person.find_by(name: 'sarah nicholas')
        observation = person.council_election_data.first

        expect(observation['state']).to eq('vic')
        expect(observation['cycle']).to eq(slug)
        expect(observation['declared_date']).to eq('2024-11-22')
      end
    end

    context 'for a countback' do
      let(:slug) { '12dec-moira-shire-countback' }
      let(:kind) { 'countback' }
      let(:council_description) { 'Moira Shire Council' }
      let(:page) { Rails.root.join('spec/fixtures/councils/vic/countback_declared.html').read }

      it 'records the elected candidate as a Person with an undated Councillor Membership' do
        described_class.new.perform(slug, kind, council_description)

        council = Group.find_by(name: 'Moira Shire Council')
        person = Person.find_by(name: 'wendy buck')
        membership = Membership.find_by(group: council, member: person)

        expect(membership.start_date).to be_nil
        expect(membership.evidence).to include('Victorian Electoral Commission countback declared results')
      end

      it 'appends a raw observation dated to the countback date' do
        described_class.new.perform(slug, kind, council_description)

        person = Person.find_by(name: 'wendy buck')
        observation = person.council_election_data.first

        expect(observation['declared_date']).to eq('2022-12-12')
      end
    end

    context 'when the result page has not been declared yet' do
      let(:slug) { '12dec-moira-shire-countback' }
      let(:kind) { 'countback' }
      let(:council_description) { 'Moira Shire Council' }
      let(:page) { '<html><body><table><tr><th>Vacancy date</th><td>3 November 2022</td></tr></table></body></html>' }

      it 'does not raise or create anything' do
        expect { described_class.new.perform(slug, kind, council_description) }.not_to raise_error
        expect(Group.find_by(name: 'Moira Shire Council')).to be_nil
      end
    end

    context 'when the result page fails to download' do
      let(:slug) { '12dec-moira-shire-countback' }
      let(:kind) { 'countback' }
      let(:council_description) { 'Moira Shire Council' }
      let(:page) { nil }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform(slug, kind, council_description) }.to raise_error(RuntimeError, /Failed to download/)
        expect(ApiLog.last.endpoint).to eq(url)
      end
    end
  end
end

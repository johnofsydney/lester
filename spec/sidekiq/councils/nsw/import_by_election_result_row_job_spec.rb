require 'rails_helper'

RSpec.describe Councils::Nsw::ImportByElectionResultRowJob, type: :job do
  describe '#perform' do
    let(:lb_id) { 'LB2401' }
    let(:report_url) { 'https://results.elections.nsw.gov.au/LB2401/Berrigan/Councillor/DistributionOfPreferencesReport.html' }
    let(:council_description) { 'Berrigan Shire Council' }

    before do
      allow(Group).to receive_messages(
        government_department_tag: FactoryBot.create(:group, name: 'government department tag', type: 'Tag'),
        local_councils_tag: FactoryBot.create(:group, name: 'australian local councils', type: 'Tag')
      )

      allow(Councils::PageDownloader).to receive(:call).with(report_url).and_return(page)
    end

    context 'when the by-election has been declared' do
      let(:page) { Rails.root.join('spec/fixtures/councils/nsw/by_election_declared.html').read }

      it 'creates the council as a Group tagged into Australian Local Councils' do
        described_class.new.perform(lb_id, report_url, council_description)

        council = Group.find_by(name: council_description)
        expect(council).to be_present
        expect(Membership.exists?(group: Group.local_councils_tag, member: council)).to be(true)
      end

      it 'records the elected candidate as a Person with an undated Councillor Membership' do
        described_class.new.perform(lb_id, report_url, council_description)

        council = Group.find_by(name: council_description)
        person = Person.find_by(name: 'sharon dennis')
        membership = Membership.find_by(group: council, member: person)

        expect(membership.start_date).to be_nil
        expect(membership.evidence).to include('NSW Electoral Commission by-election/countback declared results')
      end

      it 'appends a raw observation to the council_election_data, keyed by the LB id' do
        described_class.new.perform(lb_id, report_url, council_description)

        person = Person.find_by(name: 'sharon dennis')
        observation = person.council_election_data.first

        expect(observation['state']).to eq('nsw')
        expect(observation['cycle']).to eq(lb_id)
        expect(observation['declared_date']).to eq('2024-12-09')
      end
    end

    context 'when the by-election has not been declared yet' do
      let(:page) { '<html><body><table><tr class="generalRow"><td>HUMPHRIES Myles</td></tr></table></body></html>' }

      it 'does not raise or create anything' do
        expect { described_class.new.perform(lb_id, report_url, council_description) }.not_to raise_error
        expect(Group.find_by(name: council_description)).to be_nil
      end
    end

    context 'when the result page fails to download' do
      let(:page) { nil }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform(lb_id, report_url, council_description) }.to raise_error(RuntimeError, /Failed to download/)
        expect(ApiLog.last.endpoint).to eq(report_url)
      end
    end
  end
end

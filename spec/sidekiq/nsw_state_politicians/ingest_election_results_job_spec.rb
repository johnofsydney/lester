require 'rails_helper'

RSpec.describe NswStatePoliticians::IngestElectionResultsJob, type: :job do
  describe '#perform' do
    let(:event_id) { 'SG2301' }
    let(:elected_url) { "https://pastvtr.elections.nsw.gov.au/#{event_id}/LA/state/elected" }
    let(:results_index_url) { "https://pastvtr.elections.nsw.gov.au/#{event_id}/LA/results" }
    let(:elected_page) { Rails.root.join('spec/fixtures/nsw_state_politicians/la_elected.html').read }
    let(:results_index_page) { Rails.root.join('spec/fixtures/nsw_state_politicians/la_results_index.html').read }
    let(:nsw_parliament) { FactoryBot.create(:group, name: 'nsw parliament') }

    before do
      allow(Group).to receive(:nsw_parliament).and_return(nsw_parliament)
      allow(Councils::PageDownloader).to receive(:call).with(elected_url).and_return(elected_page)
      allow(Councils::PageDownloader).to receive(:call).with(results_index_url).and_return(results_index_page)
      # Real party Groups are plain Groups (type: nil), not Tags -- see
      # docs/adr/0011-tag-type-is-for-category-labels-not-organizations.md.
      FactoryBot.create(:group, name: Group::NAMES.liberals.nsw)
      FactoryBot.create(:group, name: Group::NAMES.labor.nsw)
      allow(NswStatePoliticians::ImportLaElectorateResultJob).to receive(:perform_in)
    end

    it 'records every winner from the elected page' do
      described_class.new.perform(event_id)

      expect(Person.exists?(name: 'justin clancy')).to be(true)
      expect(Person.exists?(name: 'lynda voltz')).to be(true)
    end

    it 'fans out one ImportLaElectorateResultJob per electorate slug, staggered, passing the matched winner name' do
      described_class.new.perform(event_id)

      expect(NswStatePoliticians::ImportLaElectorateResultJob).to have_received(:perform_in).with(0.seconds, event_id, 'auburn', 'VOLTZ Lynda')
      expect(NswStatePoliticians::ImportLaElectorateResultJob).to have_received(:perform_in).with(described_class::IMPORT_SPACING, event_id, 'badgerys-creek', nil)
    end

    context 'when the elected page fails to download' do
      let(:elected_page) { nil }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform(event_id) }.to raise_error(RuntimeError, /Failed to download NSW LA elected page/)
        expect(ApiLog.last.endpoint).to eq(elected_url)
      end
    end
  end
end

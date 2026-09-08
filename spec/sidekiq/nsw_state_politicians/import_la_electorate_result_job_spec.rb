require 'rails_helper'

RSpec.describe NswStatePoliticians::ImportLaElectorateResultJob, type: :job do
  describe '#perform' do
    let(:event_id) { 'SG2301' }
    let(:electorate_slug) { 'auburn' }
    let(:url) { "https://pastvtr.elections.nsw.gov.au/#{event_id}/LA/#{electorate_slug}/cc/fp_summary" }
    let(:nsw_parliament) { FactoryBot.create(:group, name: 'nsw parliament') }
    let(:page) { Rails.root.join('spec/fixtures/nsw_state_politicians/la_fp_summary.html').read }

    before do
      allow(Group).to receive(:nsw_parliament).and_return(nsw_parliament)
      allow(Councils::PageDownloader).to receive(:call).with(url).and_return(page)
      # Real party Groups are plain Groups (type: nil), not Tags -- see
      # docs/adr/0011-tag-type-is-for-category-labels-not-organizations.md.
      FactoryBot.create(:group, name: Group::NAMES.labor.nsw)
      FactoryBot.create(:group, name: Group::NAMES.greens.nsw)
      FactoryBot.create(:group, name: 'Liberal Democratic Party')
    end

    context 'when no winner_name is passed' do
      it 'records every candidate whose party already has a Group' do
        described_class.new.perform(event_id, electorate_slug)

        expect(Person.exists?(name: 'lynda voltz')).to be(true)
        expect(Person.exists?(name: 'masoomeh asgari')).to be(true)
        expect(Person.exists?(name: 'julie morkos douaihy')).to be(true)
      end

      it 'does not record the independent candidate (blank party)' do
        described_class.new.perform(event_id, electorate_slug)

        expect(Person.exists?(name: 'jamal daoud')).to be(false)
      end
    end

    context 'when winner_name matches a candidate row' do
      it 'skips that row (already recorded by the top-level job) but still records the rest' do
        described_class.new.perform(event_id, electorate_slug, 'VOLTZ Lynda')

        expect(Person.exists?(name: 'lynda voltz')).to be(false)
        expect(Person.exists?(name: 'masoomeh asgari')).to be(true)
      end
    end

    context 'when the fp_summary page fails to download' do
      let(:page) { nil }

      it 'logs to ApiLog and re-raises' do
        expect { described_class.new.perform(event_id, electorate_slug) }.to raise_error(RuntimeError, /Failed to download NSW LA fp_summary page/)
        expect(ApiLog.last.endpoint).to eq(url)
      end
    end
  end
end

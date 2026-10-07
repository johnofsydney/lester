require 'rails_helper'

RSpec.describe NswStatePoliticians::IngestLcElectionResultsJob, type: :job do
  describe '#perform' do
    let(:event_id) { 'SG2301' }
    let(:candidates_elected_url) { "https://pastvtr.elections.nsw.gov.au/#{event_id}/LC/state/candidates_elected" }
    let(:fp_by_grp_url) { "https://pastvtr.elections.nsw.gov.au/#{event_id}/LC/state/fp_by_grp" }
    let(:grp_and_candidates_url) { "https://pastvtr.elections.nsw.gov.au/#{event_id}/LC/state/fp_grp_and_candidates" }
    let(:candidates_elected_page) { Rails.root.join('spec/fixtures/nsw_state_politicians/lc_candidates_elected.html').read }
    let(:fp_by_grp_page) { Rails.root.join('spec/fixtures/nsw_state_politicians/lc_fp_by_grp.html').read }
    let(:grp_and_candidates_page) { Rails.root.join('spec/fixtures/nsw_state_politicians/lc_grp_and_candidates.html').read }
    let(:nsw_parliament) { FactoryBot.create(:group, name: 'nsw parliament') }

    before do
      allow(Group).to receive(:nsw_parliament).and_return(nsw_parliament)
      allow(Councils::PageDownloader).to receive(:call).with(candidates_elected_url).and_return(candidates_elected_page)
      allow(Councils::PageDownloader).to receive(:call).with(fp_by_grp_url).and_return(fp_by_grp_page)
      allow(Councils::PageDownloader).to receive(:call).with(grp_and_candidates_url).and_return(grp_and_candidates_page)
      FactoryBot.create(:group, name: Group::NAMES.labor.nsw)
      FactoryBot.create(:group, name: Group::NAMES.liberals.nsw)
      FactoryBot.create(:group, name: Group::NAMES.greens.nsw)
    end

    it 'records every winner from the candidates_elected page' do
      described_class.new.perform(event_id)

      expect(Person.exists?(name: 'courtney houssos')).to be(true)
      expect(Person.exists?(name: 'natasha maclaren-jones')).to be(true)
      expect(Person.exists?(name: 'catriona faehrmann')).to be(true) # People::RecordPerson's hardcoded Cate -> Catriona override
    end

    it 'gives winners an NSW Parliament Membership with the LC title' do
      described_class.new.perform(event_id)

      person = Person.find_by(name: 'courtney houssos')
      membership = Membership.find_by(group: nsw_parliament, member: person)
      expect(membership.positions.pluck(:title)).to eq(['Member of the Legislative Council'])
    end

    it 'records an EXCLUDED candidate whose group\'s party resolves, without double-recording an already-elected winner' do
      described_class.new.perform(event_id)

      # SHELTON Lyle (group A, no declared party name on fp_by_grp) is not ingested
      expect(Person.exists?(name: 'lyle shelton')).to be(false)
      # SOME Otherperson (group D, LABOR -- an existing Group) is an ingested loser
      otherperson = Person.find_by(name: 'otherperson some')
      expect(otherperson).to be_present
      expect(Membership.exists?(group: Group.find_by(name: Group::NAMES.labor.nsw), member: otherperson)).to be(true)
      expect(Membership.exists?(group: nsw_parliament, member: otherperson)).to be(false)
      # HOUSSOS Courtney appears once in candidates_elected and once (as ELECTED) in
      # grp_and_candidates -- only one Person, one Parliament Membership either way.
      expect(Person.where(name: 'courtney houssos').count).to eq(1)
      expect(Membership.where(group: nsw_parliament, member: Person.find_by(name: 'courtney houssos')).count).to eq(1)
    end

    context 'when the candidates_elected page fails to download' do
      let(:candidates_elected_page) { nil }

      it 'records an ingest failure and re-raises' do
        expect { described_class.new.perform(event_id) }.to raise_error(RuntimeError, /Failed to download NSW LC candidates_elected page/)
        expect(IngestSourceStatus.find_by(key: described_class.name).last_failure_at).to be_present
      end
    end
  end
end

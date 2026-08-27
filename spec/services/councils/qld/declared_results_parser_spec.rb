require 'rails_helper'

RSpec.describe Councils::Qld::DeclaredResultsParser, type: :service do
  subject(:call_service) { described_class.call(declared_candidates_page:, electorates_page:, source_url:, known_council_names:) }

  let(:declared_candidates_page) { Rails.root.join('spec/fixtures/councils/qld/2024qlge_declared_candidates.json').read }
  let(:electorates_page) { Rails.root.join('spec/fixtures/councils/qld/2024qlge_electorates.json').read }
  let(:source_url) { 'https://resultsdata.elections.qld.gov.au/2024QLGE-declared_candidates.json' }
  let(:known_council_names) { ['Aurukun Shire', 'Banana Shire', 'Brisbane City', 'Ipswich City'] }

  it 'does no network fetch -- a pure function of its given inputs' do
    allow(Councils::PageDownloader).to receive(:call)

    call_service

    expect(Councils::PageDownloader).not_to have_received(:call)
  end

  it 'normalises a single-winner mayoral contest' do
    contest = call_service.find { |c| c[:contest_name] == 'Aurukun Shire' }

    expect(contest).to eq(
      council_name: 'Aurukun Shire',
      contest_name: 'Aurukun Shire',
      contest_type: 'mayor',
      candidates: [{ name: 'BANDICOOTCHA, Barbara Sue', party: nil }],
      declared_date: Date.new(2024, 3, 28),
      source_url:
    )
  end

  it 'normalises a multi-winner councillor contest' do
    contest = call_service.find { |c| c[:contest_name] == 'Aurukun Shire Division 1' }

    expect(contest[:council_name]).to eq('Aurukun Shire')
    expect(contest[:contest_type]).to eq('councillor')
    expect(contest[:candidates]).to contain_exactly(
      { name: 'MARROTT, Jayden Isaac', party: nil },
      { name: 'YUNKAPORTA, Leona Nanette', party: nil },
      { name: 'KOOMEETA, Craig Allan', party: nil },
      { name: 'YUNKAPORTA, Eloise Susie Gladys N', party: nil }
    )
  end

  it 'captures party where declared, including on a single-winner ward contest' do
    contest = call_service.find { |c| c[:contest_name] == 'Brisbane City Bracken Ridge' }

    expect(contest[:candidates]).to eq([{ name: 'LANDERS, Sandra Jane Marie', party: 'Liberal National Party of Queensland' }])
  end

  it 'resolves a named-ward contest to its council via the given known-council names, not a Division-suffix guess' do
    contest = call_service.find { |c| c[:contest_name] == 'Brisbane City Calamvale' }

    expect(contest[:council_name]).to eq('Brisbane City')
  end

  it 'parses every contest in the fixture' do
    expect(call_service.size).to eq(17)
  end

  context 'with a by-election (single electorate, no lgaName or parentElectorateId to resolve from)' do
    let(:declared_candidates_page) { Rails.root.join('spec/fixtures/councils/qld/msc24_declared_candidates.json').read }
    let(:electorates_page) { Rails.root.join('spec/fixtures/councils/qld/msc24_electorates.json').read }
    let(:source_url) { 'https://resultsdata.elections.qld.gov.au/MSC24-declared_candidates.json' }
    let(:known_council_names) { ['Mornington Shire'] }

    it 'still resolves the council name from the given list and normalises the single-winner contest' do
      expect(call_service).to eq(
        [
          {
            council_name: 'Mornington Shire',
            contest_name: 'Mornington Shire Division 1',
            contest_type: 'councillor',
            candidates: [{ name: 'AH KIT, Maureen Jane', party: nil }],
            declared_date: Date.new(2024, 6, 17),
            source_url:
          }
        ]
      )
    end
  end
end

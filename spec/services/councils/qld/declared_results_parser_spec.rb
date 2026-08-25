require 'rails_helper'

RSpec.describe Councils::Qld::DeclaredResultsParser, type: :service do
  subject(:call_service) { described_class.call(stub) }

  let(:stub) { '2024QLGE' }
  let(:declared_candidates_url) { format(described_class::DECLARED_CANDIDATES_URL, stub:) }
  let(:electorates_url) { format(described_class::ELECTORATES_URL, stub:) }

  before do
    allow(Councils::PageDownloader).to receive(:call)
      .with(declared_candidates_url)
      .and_return(Rails.root.join('spec/fixtures/councils/qld/2024qlge_declared_candidates.json').read)
    allow(Councils::PageDownloader).to receive(:call)
      .with(electorates_url)
      .and_return(Rails.root.join('spec/fixtures/councils/qld/2024qlge_electorates.json').read)

    allow(Councils::Qld::KnownCouncils).to receive(:resolve) do |electorate_name|
      electorate_name.sub(/\s+Division\s+\d+\z/, '').sub(/\s+(Bracken Ridge|Calamvale)\z/, '')
    end
  end

  it 'normalises a single-winner mayoral contest' do
    contest = call_service.find { |c| c[:contest_name] == 'Aurukun Shire' }

    expect(contest).to eq(
      council_name: 'Aurukun Shire',
      contest_name: 'Aurukun Shire',
      contest_type: 'mayor',
      candidates: [{ name: 'BANDICOOTCHA, Barbara Sue', party: nil }],
      declared_date: Date.new(2024, 3, 28),
      source_url: declared_candidates_url
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

  it 'resolves a named-ward contest to its council via KnownCouncils, not a Division-suffix guess' do
    contest = call_service.find { |c| c[:contest_name] == 'Brisbane City Calamvale' }

    expect(contest[:council_name]).to eq('Brisbane City')
  end

  it 'parses every contest in the fixture' do
    expect(call_service.size).to eq(17)
  end

  context 'with a by-election stub (single electorate, no lgaName or parentElectorateId to resolve from)' do
    let(:stub) { 'MSC24' }

    before do
      allow(Councils::PageDownloader).to receive(:call)
        .with(declared_candidates_url)
        .and_return(Rails.root.join('spec/fixtures/councils/qld/msc24_declared_candidates.json').read)
      allow(Councils::PageDownloader).to receive(:call)
        .with(electorates_url)
        .and_return(Rails.root.join('spec/fixtures/councils/qld/msc24_electorates.json').read)
      allow(Councils::Qld::KnownCouncils).to receive(:resolve).with('Mornington Shire Division 1').and_return('Mornington Shire')
    end

    it 'still resolves the council name via KnownCouncils and normalises the single-winner contest' do
      expect(call_service).to eq(
        [
          {
            council_name: 'Mornington Shire',
            contest_name: 'Mornington Shire Division 1',
            contest_type: 'councillor',
            candidates: [{ name: 'AH KIT, Maureen Jane', party: nil }],
            declared_date: Date.new(2024, 6, 17),
            source_url: declared_candidates_url
          }
        ]
      )
    end
  end
end

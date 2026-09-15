require 'rails_helper'

RSpec.describe Councils::Nsw::ByElectionIndexParser, type: :service do
  let(:page) { Rails.root.join('spec/fixtures/councils/nsw/local_election_results_archive.html').read }

  it 'excludes general-cycle headings' do
    descriptions = described_class.call(page).map { |event| event[:council_description] }

    expect(descriptions).not_to include(a_string_matching(/NSW Local Government elections/i))
  end

  it 'excludes legacy events with no results.elections.nsw.gov.au report link' do
    lb_ids = described_class.call(page).map { |event| event[:lb_id] }

    expect(lb_ids).not_to include('LB1403')
  end

  it 'returns the LB id, DoP report URL and a stripped council description for each event' do
    expect(described_class.call(page)).to contain_exactly(
      {
        lb_id: 'LB2510',
        report_url: 'https://results.elections.nsw.gov.au/LB2510/Central_Darling/Central_Darling_A/Councillor/DistributionOfPreferencesReport.html',
        council_description: 'Central Darling Shire Council'
      },
      {
        lb_id: 'LB2401',
        report_url: 'https://results.elections.nsw.gov.au/LB2401/Berrigan/Councillor/DistributionOfPreferencesReport.html',
        council_description: 'Berrigan Shire Council'
      },
      {
        lb_id: 'LB1801',
        report_url: 'https://results.elections.nsw.gov.au/LB1801/Murrumbidgee/Murrumbidgee%20East/Councillor/DistributionOfPreferencesReport.html',
        council_description: 'Murrumbidgee Council'
      }
    )
  end

  context 'when the page has no matching headings' do
    let(:page) { '<html><body>nothing</body></html>' }

    it 'returns an empty array' do
      expect(described_class.call(page)).to eq([])
    end
  end
end

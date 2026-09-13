require 'rails_helper'

describe AuGrants::XlsxParser, type: :service do
  let(:parser) { described_class.new }

  context 'with a day that has published grants' do
    let(:path) { Rails.root.join('spec/fixtures/au_grants/grants_2026-01-06.xlsx') }

    it 'returns an Array of row hashes with no blank/malformed rows' do
      rows = parser.call(path)

      expect(rows).to be_an(Array)
      expect(rows.size).to eq(32)
      expect(rows).to all(satisfy { |row| row['GA ID'].present? })
    end

    it 'converts date cells to ISO8601 strings, not Date objects' do
      rows = parser.call(path)

      expect(rows.first['Publish Date']).to match(/\A\d{4}-\d{2}-\d{2}\z/)
    end
  end

  context 'with a day that has zero published grants' do
    let(:path) { Rails.root.join('spec/fixtures/au_grants/grants_2026-01-03_no_results.xlsx') }

    it 'returns an empty Array rather than a fake row from the "no results" message' do
      rows = parser.call(path)

      expect(rows).to eq([])
    end
  end
end

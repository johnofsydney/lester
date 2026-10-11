require 'rails_helper'

RSpec.describe FileIngestor, type: :service do
  describe '#initialize' do
    it 'raises when given neither csv nor file' do
      expect { described_class.new }.to raise_error(RuntimeError)
    end

    it 'accepts a pre-parsed CSV::Table' do
      csv = CSV::Table.new([])

      expect(described_class.new(csv: csv).csv).to eq(csv)
    end
  end

  describe '#general_upload' do
    subject(:ingestor) { described_class.new(csv: csv) }

    let(:csv) do
      CSV.parse(<<~CSV, headers: true)
        person,group,title,evidence,start_date,end_date
        Jane Example,Example Group,ceo,http://example.com/evidence,2020-01-01,2021-01-01
      CSV
    end

    # #general_upload currently raises unconditionally before it ever reaches the loop
    # (deliberately disabled - see "mapper id broken - fix later" at the top of the
    # method). It isn't scheduled anywhere (absent from config/sidekiq.yml); it's only
    # reachable via the admin "General Upload" bulk-paste action, which itself calls
    # FileIngestor.general_upload(csv:) as a class method that doesn't exist on this
    # class. This spec documents the current disabled state rather than asserting a
    # happy path the method doesn't currently have.
    it 'is currently disabled and raises before processing any row' do
      expect { ingestor.general_upload }.to raise_error('mapper id broken - fix later')

      expect(Person.count).to eq(0)
      expect(Group.count).to eq(0)
    end
  end
end

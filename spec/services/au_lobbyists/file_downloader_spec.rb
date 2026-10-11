require 'rails_helper'

RSpec.describe AuLobbyists::FileDownloader, type: :service do
  subject(:downloader) { described_class.new }

  # Real xlsx bytes are needed because #call hands the response body straight to
  # Roo::Excelx - any real workbook will do, this test is about the download/convert/
  # cleanup mechanics, not lobbyist-specific content.
  let(:xlsx_bytes) { Rails.root.join('spec/fixtures/au_grants/grants_2026-01-06.xlsx').binread }
  let(:xlsx_path) { Rails.root.join('tmp/lobbyists.xlsx') }
  let(:csv_path) { Rails.root.join('tmp/grantconnect-grant-award-publis.csv') }
  let(:connection) { double('Faraday::Connection', post: response) } # rubocop:disable RSpec/VerifiedDoubles

  before do
    allow(Faraday).to receive(:new).and_return(connection)
  end

  after do
    FileUtils.rm_f(xlsx_path)
    FileUtils.rm_f(csv_path)
  end

  describe '#call' do
    context 'when the download succeeds (happy path)' do
      let(:response) { double('Faraday::Response', success?: true, body: xlsx_bytes) } # rubocop:disable RSpec/VerifiedDoubles

      it 'converts each sheet to a csv file, cleans up the temp xlsx, and returns true' do
        result = downloader.call

        expect(result).to be(true)
        expect(File.exist?(csv_path)).to be(true)
        expect(File.read(csv_path)).not_to be_empty
        expect(File.exist?(xlsx_path)).to be(false)
      end
    end

    context 'when the download fails' do
      let(:response) { double('Faraday::Response', success?: false, status: 500, body: 'error') } # rubocop:disable RSpec/VerifiedDoubles

      it 'returns false without writing any files' do
        result = downloader.call

        expect(result).to be(false)
        expect(File.exist?(csv_path)).to be(false)
      end
    end

    context 'when deleting the temp xlsx file raises' do
      let(:response) { double('Faraday::Response', success?: true, body: xlsx_bytes) } # rubocop:disable RSpec/VerifiedDoubles

      before do
        allow(File).to receive(:delete).and_call_original
        allow(File).to receive(:delete).with(xlsx_path).and_raise(Errno::EACCES, 'permission denied')
      end

      it 'logs the error instead of raising, and still returns true' do
        expect(downloader.call).to be(true)
      end
    end
  end
end

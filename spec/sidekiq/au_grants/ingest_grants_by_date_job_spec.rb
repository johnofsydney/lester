require 'rails_helper'

RSpec.describe AuGrants::IngestGrantsByDateJob, type: :job do
  let(:path) { Rails.root.join('tmp/grants_2026-01-05.xlsx') }
  let(:rows) do
    [
      { 'GA ID' => 'GA1' },
      { 'GA ID' => 'GA2' }
    ]
  end

  before do
    allow(AuGrants::GrantsDownloader).to receive(:new).and_return(instance_double(AuGrants::GrantsDownloader, call: path))
    allow(AuGrants::XlsxParser).to receive(:new).and_return(
      instance_double(AuGrants::XlsxParser, call: nil).tap do |parser|
        allow(parser).to receive(:call).with(path) { |&block| rows.each(&block) }
      end
    )
    allow(AuGrants::IngestSingleGrantJob).to receive(:perform_async)
  end

  it 'downloads the day, parses it, and enqueues a job per row' do
    described_class.new.perform('2026-01-05')

    expect(AuGrants::IngestSingleGrantJob).to have_received(:perform_async).with(rows[0])
    expect(AuGrants::IngestSingleGrantJob).to have_received(:perform_async).with(rows[1])
  end
end

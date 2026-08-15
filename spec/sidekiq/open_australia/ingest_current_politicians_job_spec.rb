require 'rails_helper'

RSpec.describe OpenAustralia::IngestCurrentPoliticiansJob, type: :job do
  subject(:perform) { described_class.new.perform }

  before do
    allow(OpenAustralia::IngestCurrentPoliticians).to receive(:call)
  end

  it 'delegates to OpenAustralia::IngestCurrentPoliticians' do
    perform
    expect(OpenAustralia::IngestCurrentPoliticians).to have_received(:call)
  end

  context 'when it raises' do
    before do
      allow(OpenAustralia::IngestCurrentPoliticians).to receive(:call).and_raise(StandardError, 'boom')
    end

    it 're-raises and logs an ApiLog entry' do
      expect { perform }.to raise_error(StandardError, 'boom').and change(ApiLog, :count).by(1)
    end
  end
end

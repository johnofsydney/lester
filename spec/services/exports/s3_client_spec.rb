require 'rails_helper'

RSpec.describe Exports::S3Client, type: :service do
  let(:stubbed_client) { Aws::S3::Client.new(stub_responses: true, region: 'ap-southeast-2') }

  before do
    allow(Aws::S3::Client).to receive(:new).and_return(stubbed_client)
    allow(Rails.application.credentials).to receive(:[]).and_call_original
    allow(Rails.application.credentials).to receive(:[]).with(:aws).and_return(
      {
        s3_export_bucket: 'test-bucket',
        region: 'ap-southeast-2',
        access_key_id: 'key-id',
        secret_access_key: 'secret'
      }
    )
  end

  describe '#initialize' do
    it 'raises a clear error instead of reaching the AWS SDK when credentials are missing' do
      allow(Rails.application.credentials).to receive(:[]).with(:aws).and_return(
        { s3_export_bucket: 'test-bucket', region: 'ap-southeast-2', access_key_id: nil, secret_access_key: '' }
      )

      expect { described_class.new }.to raise_error(
        Exports::S3Client::ConfigurationError,
        'Missing Rails.application.credentials.aws keys: access_key_id, secret_access_key'
      )
    end

    it 'raises when the aws credentials block is absent entirely' do
      allow(Rails.application.credentials).to receive(:[]).with(:aws).and_return(nil)

      expect { described_class.new }.to raise_error(Exports::S3Client::ConfigurationError)
    end
  end

  describe '#upload' do
    it 'puts the object into the configured bucket' do
      allow(stubbed_client).to receive(:put_object).and_call_original

      described_class.upload('summary.json', '{}')

      expect(stubbed_client).to have_received(:put_object).with(bucket: 'test-bucket', key: 'summary.json', body: '{}')
    end
  end

  describe '#delete' do
    it 'deletes the object from the configured bucket' do
      allow(stubbed_client).to receive(:delete_object).and_call_original

      described_class.delete('summary.json')

      expect(stubbed_client).to have_received(:delete_object).with(bucket: 'test-bucket', key: 'summary.json')
    end
  end

  describe '#list' do
    it 'returns objects sorted most-recently-modified first' do
      stubbed_client.stub_responses(:list_objects_v2, contents: [
                                      { key: 'older.json', last_modified: Time.zone.parse('2026-01-01') },
                                      { key: 'newer.json', last_modified: Time.zone.parse('2026-06-01') }
                                    ])

      expect(described_class.list.map(&:key)).to eq(%w[newer.json older.json])
    end
  end

  describe '#public_url' do
    it 'builds the regional S3 URL for the key' do
      expect(described_class.public_url('summary.json'))
        .to eq('https://test-bucket.s3.ap-southeast-2.amazonaws.com/summary.json')
    end
  end
end

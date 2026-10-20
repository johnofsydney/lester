require 'rails_helper'

RSpec.describe Exports::UploadKeyContentsJob, type: :job do
  before { allow(Exports::S3Client).to receive_messages(upload: true, delete: true) }

  describe '#perform' do
    it 'uploads the contents to the given key' do
      described_class.new.perform('person/jane_1.json', '{"money_in":100}')

      expect(Exports::S3Client).to have_received(:upload).with('person/jane_1.json', '{"money_in":100}')
    end

    it 'does not attempt to delete anything when there is no previous key' do
      described_class.new.perform('person/jane_1.json', '{}')

      expect(Exports::S3Client).not_to have_received(:delete)
    end

    it 'does not attempt to delete when the previous key is the same as the current one' do
      described_class.new.perform('person/jane_1.json', '{}', 'person/jane_1.json')

      expect(Exports::S3Client).not_to have_received(:delete)
    end

    it 'deletes the previous key once the new key has been written, when the key has changed' do
      described_class.new.perform('person/jane_1.json', '{}', 'person/old_name_1.json')

      expect(Exports::S3Client).to have_received(:upload).with('person/jane_1.json', '{}')
      expect(Exports::S3Client).to have_received(:delete).with('person/old_name_1.json')
    end

    it 'logs then re-raises when the upload fails' do
      allow(Exports::S3Client).to receive(:upload).and_raise(StandardError, 'boom')
      allow(Rails.logger).to receive(:error)

      expect { described_class.new.perform('person/jane_1.json', '{}') }.to raise_error(StandardError, 'boom')

      expect(Rails.logger).to have_received(:error).with('Error uploading node JSON to S3 for key person/jane_1.json: boom')
      expect(Exports::S3Client).not_to have_received(:delete)
    end
  end
end

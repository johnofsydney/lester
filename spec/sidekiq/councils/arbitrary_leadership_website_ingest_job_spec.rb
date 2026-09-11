require 'rails_helper'

RSpec.describe Councils::ArbitraryLeadershipWebsiteIngestJob, type: :job do
  describe '#perform' do
    it 'logs the given council name' do
      allow(Rails.logger).to receive(:info)

      described_class.new.perform('City of Liverpool')

      expect(Rails.logger).to have_received(:info).with(/City of Liverpool/)
    end
  end
end

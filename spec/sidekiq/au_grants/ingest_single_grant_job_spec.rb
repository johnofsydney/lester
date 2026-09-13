require 'rails_helper'

RSpec.describe AuGrants::IngestSingleGrantJob, type: :job do
  let(:row) { { 'GA ID' => 'GA1' } }

  before do
    allow(AuGrants::RecordIndividualGrant).to receive(:call)
  end

  it 'records the row as an individual grant' do
    described_class.new.perform(row)

    expect(AuGrants::RecordIndividualGrant).to have_received(:call) do |release|
      expect(release).to be_an_instance_of(AuGrants::Release)
      expect(release.ga_id).to eq('GA1')
    end
  end
end

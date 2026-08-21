require 'rails_helper'

RSpec.describe OpenAustralia::MaxKnownPersonId, type: :service do
  subject(:call) { described_class.call }

  let(:api_client) { instance_double(OpenAustralia::ApiClient) }

  before do
    allow(OpenAustralia::ApiClient).to receive(:new).and_return(api_client)
    allow(api_client).to receive_messages(
      get_representatives: [{ 'person_id' => '100' }, { 'person_id' => '10350' }],
      get_senators: [{ 'person_id' => '9999' }]
    )
  end

  it 'returns the highest person_id across both chambers' do
    expect(call).to eq(10_350)
  end
end

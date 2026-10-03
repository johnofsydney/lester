require 'rails_helper'

RSpec.describe Abn::GroupNameUpdater, type: :service do
  let(:group) { FactoryBot.create(:group, name: 'Old Name') }
  let(:result) do
    {
      abn: '53004085616',
      main_name: 'Acme Holdings Pty Ltd',
      trading_names: ['Acme', 'Acme Holdings Pty Ltd']
    }
  end

  before do
    group.update!(business_number: '53004085616')
    allow(Abn::FetchBusinessNames).to receive(:call).and_return(result)
  end

  it 'updates the group name from the ABN main name' do
    described_class.call(group)

    expect(group.reload.name).to eq('acme holdings pty ltd')
  end

  it 'records ABN trading names with abn source, skipping the group\'s own name' do
    described_class.call(group)

    expect(group.trading_names.pluck(:name, :source)).to contain_exactly(%w[acme abn])
  end

  it 'preserves ingest-sourced trading names across a refresh' do
    group.trading_names.create!(name: 'Ingested Alias', source: 'ingest')

    described_class.call(group)

    expect(group.trading_names.pluck(:name)).to include('ingested alias')
  end

  it 'replaces previously ABN-sourced trading names' do
    group.trading_names.create!(name: 'Stale Abn Alias', source: 'abn')

    described_class.call(group)

    expect(group.trading_names.pluck(:name)).not_to include('stale abn alias')
  end

  it 'does nothing when the group has no business number' do
    group.update!(business_number: nil)

    described_class.call(group)

    expect(Abn::FetchBusinessNames).not_to have_received(:call)
  end
end

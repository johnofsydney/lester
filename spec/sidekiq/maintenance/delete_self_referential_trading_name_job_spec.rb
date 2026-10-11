require 'rails_helper'

RSpec.describe Maintenance::DeleteSelfReferentialTradingNameJob, type: :job do
  let(:group) { FactoryBot.create(:group, name: 'Banana Shire Council') }
  let!(:trading_name) { TradingName.create!(owner: group, name: 'Banana Shire Council') }

  it 'destroys a trading name identical to its owner\'s name' do
    expect { described_class.new.perform(trading_name.id) }.to change(TradingName, :count).by(-1)
    expect(TradingName.exists?(trading_name.id)).to be(false)
  end

  it 'skips a trading name that no longer matches its owner\'s name' do
    group.update!(name: 'Renamed Council')

    expect { described_class.new.perform(trading_name.id) }.not_to change(TradingName, :count)
    expect(TradingName.exists?(trading_name.id)).to be(true)
  end

  it 'does nothing when the trading name has already been deleted' do
    id = trading_name.id
    trading_name.destroy!

    expect { described_class.new.perform(id) }.not_to raise_error
  end
end

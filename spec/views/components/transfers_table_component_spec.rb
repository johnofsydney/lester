require 'rails_helper'

RSpec.describe TransfersTableComponent, type: :component do
  let(:entity) { OpenStruct.new(id: 9, klass: 'Group') }
  let(:transfer) do
    OpenStruct.new(
      id: 1,
      amount: 100,
      effective_date: Date.new(2024, 6, 1),
      giver_id: 1,
      giver_type: 'Person',
      giver_name: 'giver',
      taker_id: 2,
      taker_type: 'Group',
      taker_name: 'taker',
      depth: 0,
      direction: 'outgoing'
    )
  end

  describe '#view_template' do
    it 'renders nothing when there are no transfers' do
      html = described_class.new(transfers: [], heading: 'Transfers', entity: entity).call

      expect(html).to be_blank
    end

    it 'renders the table directly when neither summarise_for nor exclude is given (happy path)' do
      html = described_class.new(transfers: [transfer], heading: 'Transfers', entity: entity).call

      expect(html).to include('Taker')
      expect(html).to include('$100')
    end

    it 'renders the table directly when summarise_for and exclude are both present but empty' do
      html = described_class.new(
        transfers: [transfer],
        heading: 'Transfers',
        entity: entity,
        summarise_for: [],
        exclude: []
      ).call

      expect(html).to include('Taker')
    end

    it 'summarises transfers to takers in summarise_for' do
      other_transfer = OpenStruct.new(
        id: 2,
        amount: 50,
        effective_date: Date.new(2024, 6, 1),
        giver_id: 3,
        giver_type: 'Person',
        giver_name: 'other giver',
        taker_id: 2,
        taker_type: 'Group',
        taker_name: 'taker',
        depth: 0,
        direction: 'outgoing'
      )

      html = described_class.new(
        transfers: [transfer, other_transfer],
        heading: 'Transfers',
        entity: entity,
        summarise_for: ['taker']
      ).call

      expect(html.downcase).to include('2 individual records, from various donors')
    end

    # `exclude` matches on t.taker.name (not t.taker_name, which the rest of this file
    # uses) and no caller in the app passes exclude: today - this documents current
    # behaviour against a double that responds to #taker, not against real cached data.
    it 'excludes transfers whose taker is in the exclude list' do
      excluded_transfer = double('transfer', taker: double('taker', name: 'taker'), amount: 10) # rubocop:disable RSpec/VerifiedDoubles

      html = described_class.new(
        transfers: [excluded_transfer],
        heading: 'Transfers',
        entity: entity,
        exclude: ['taker']
      ).call

      expect(html).not_to include('$10')
    end
  end
end

require 'rails_helper'

describe Common::MoneyGraphs do
  let(:current_group) { Group.create(name: 'Current Group') }
  let(:giving_group_one) { Group.create(name: 'Giving Group One') }
  let(:giving_group_two) { Group.create(name: 'Giving Group Two') }
  let(:giving_group_three) { Group.create(name: 'Giving Group Three') }
  let(:giving_group_four) { Group.create(name: 'Giving Group Four') }
  let(:giving_group_five) { Group.create(name: 'Giving Group Five') }
  let(:giving_group_six) { Group.create(name: 'Giving Group Six') }
  let(:giving_group_seven) { Group.create(name: 'Giving Group Seven') }
  let(:giving_group_eight) { Group.create(name: 'Giving Group Eight') }

  before do
    Transfer.create(giver: giving_group_one, taker: current_group, amount: 1000, effective_date: '2022-01-01')
    Transfer.create(giver: giving_group_two, taker: current_group, amount: 2000, effective_date: '2022-06-01')
    Transfer.create(giver: giving_group_three, taker: current_group, amount: 3000, effective_date: '2023-01-01')
    Transfer.create(giver: giving_group_four, taker: current_group, amount: 4000, effective_date: '2023-02-01')

  end

  describe '#group_by_name' do
    context 'when the current entity is the taker (giver is false)' do
      context 'when there are five or fewer giving groups' do
        # {
        #   "Australian Bureau of Stati..."=>131560.0,
        #   "Australian Office of Finan..."=>3300000.0,
        #   "Department of Home Affairs..."=>423802636.12
        # }

        it 'returns a array of transfers grouped by name' do
          graph = described_class.new(entity: current_group, giver: false)
          expect(graph.group_by_name).to contain_exactly(['Giving Group Four', 4000.0], ['Giving Group One', 1000.0], ['Giving Group Three', 3000.0], ['Giving Group Two', 2000.0])
        end
      end

      context 'when there are more than five giving groups' do
        # [
        #   ["University of NSW", 250000.0],
        #   ["Nationals (Federal)", 269306.0],
        #   ["Others", 603999.0],
        #   ["Liberals (Federal)", 1956418.0],
        #   ["ALP (Federal)", 2201007.0],
        #   ["Australians for Indigenous...", 5010126.0]
        # ]

        before do
          Transfer.create(giver: giving_group_five, taker: current_group, amount: 5000, effective_date: '2023-03-01')
          Transfer.create(giver: giving_group_six, taker: current_group, amount: 6000, effective_date: '2023-04-01')
          Transfer.create(giver: giving_group_seven, taker: current_group, amount: 7000, effective_date: '2023-05-01')
          Transfer.create(giver: giving_group_eight, taker: current_group, amount: 8000, effective_date: '2023-06-01')
        end

        it 'returns a array of transfers grouped by name' do
          graph = described_class.new(entity: current_group, giver: false)
          expect(graph.group_by_name).to contain_exactly(['Giving Group Four', 4000.0], ['Giving Group Five', 5000.0], ['Giving Group Six', 6000.0], ['Others', 6000.0], ['Giving Group Seven', 7000.0], ['Giving Group Eight', 8000.0])
        end
      end
    end
  end

  describe '#group_by_year' do
    # {
    #   2018=>899732.0,
    #   2019=>516784.0,
    #   2020=>686515.0,
    #   2021=>792481.0,
    #   2022=>808112.0,
    #   2023=>2697876.0,
    #   2024=>3889356.0
    # }
    it 'returns a hash of transfers grouped by year' do
      graph = described_class.new(entity: current_group, giver: false)

      expect(graph.group_by_year).to eq(
        {
          2022 => 3000.0,
          2023 => 7000.0
        }
      )
    end
  end
end
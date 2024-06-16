require 'rails_helper'
require 'spec_helper'

RSpec.describe RecordPersonOrGroup, type: :service do
  describe '#person_or_group' do

    let(:people_names) do
      [
        'Natale, Darren',
        'Sedgman, Lynette',
        'Staley, Louise',
        'Warriner, Kenneth',
        'Dr Monique Ryan MP',
        'MS Allegra Spender MP',
        'Andrew D M Murray AM',
        'Hon Paul Everingham',
        'Ian Wall AM',
        'Roland Williams CBE',
        'Mr. Chris Morbey',
        'Ms. Stephanie Reed',
        'Antony Pasin MP',
        'Andrew Wilkie',
        'Faehrmann, Catriona',
        'Mcleod, Fiona',
        'Murray, Ronald James',
        "O'rourke, Barry Leonard",
        'Pitcher, Ronald',
        'Sriranganathan, Jonathan',
        'Strofield, Jonathan',
        'Wanless, Ronald',
        'Hon Paul Everingham',
        'Spencer Grammer'
      ]
    end

    it 'expect all people to be reported as person' do
      people_names.each do |name|
        expect(RecordPersonOrGroup.new(name).person_or_group).to eq('person')
      end
    end


    let(:group_names) do
      [
        'INPEX',
        'Telstra Corporation',
        'Westpac Banking Corporation',
        'AGS World Transport',
        'Alpha Tax Aid',
        'BB Win Win Outcomes',
        'Balwyn Lifestyle Centre',
        'Blossom Publications',
        'Boileau Business Technology',
        'CEPU Plumbing Division Federal Office',
        'CMAX Advisory',
        'Carrum Downs Regional Shopping Centre',
        'Charters Towers Toyota',
        'Cocoons SDA Care',
        'Deutsche Bank AG',
        'Deloitte Touche Tohmatsu',
        'Foodland Promotions',
        'Garnaut Private Wealth',
        'HCF',
        'Holmes Institute',
        'IComply Horticultural',
        'Ikon Cleaning Service',
        'Intalock Technologies',
        'Integrated Waste Services',
        'LESVOS INVESTMENTS',
        'Live Entertainment WA Inc',
        'Melbourne Institute of Technology',
        'Moby Dicks/Collective Events',
        'National Transport Insurance',
        'Nimbin Hemp Inc',
        'Victorian Automobile Chamber of Commerce',
        'Wells Haslem Mayhew Strategic Public Affairs',
        'Wentworth Cattle Company',
        'Westpac Banking Corporation',
        'Westreet Investments',
        'WorkPac',
        'Wren Oil',
        'Alp Vic Branch',
        'CEC',
        'Clp-Nt',
        'Contura Mining',
        'Lib - Fed',
        'Lib - Sa',
        'Lib - Vic',
        'Lib - Wa',
        'Lib Fed',
        'Lib Vic',
        'Lib-Act',
        'Lib-Fec',
        'Lib-Fed',
        'Lib-Sa',
        'Lib-Tas',
        'Lib-Vic',
        'Lib-Wa',
        'Nat - Fed',
        'Nat-Fed',
        'Spectrum Health',
        'Victorian Socialists',
        'Warringah Independent'
      ]
    end

    it 'expect all groups to be reported as group', :aggregate_failures do
      group_names.each do |name|
        expect(RecordPersonOrGroup.new(name).person_or_group).to eq('group')
      end
    end
  end
end
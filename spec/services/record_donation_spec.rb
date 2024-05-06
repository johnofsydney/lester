require 'rails_helper'
require 'spec_helper'

RSpec.describe RecordDonation, type: :service do
  describe '#person_or_group' do

    let(:people_names) do
      [
        'Natale, Darren',
        'Sedgman, Lynette',
        'Staley, Louise',
        'Warriner, Kenneth',
      ]
    end

    it 'expect all people to be reported as person' do
      people_names.each do |name|
        expect(RecordDonation.new(name).person_or_group).to eq('person')
      end
    end
  end

    let(:group_names) do
      [
        'HCF',
        'INPEX',
        'Telstra Corporation',
        'Westpac Banking Corporation'
      ]
    end

    it 'expect all groups to be reported as group' do
      group_names.each do |name|
        expect(RecordDonation.new(name).person_or_group).to eq('group')
      end
    end
  end

end
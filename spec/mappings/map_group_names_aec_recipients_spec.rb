require 'rails_helper'
require 'spec_helper'

RSpec.describe MapGroupNamesAecRecipients, type: :service do
  describe '#call' do
    context 'for smaller political parties' do
      it 'returns "Liberal Democratic Party" for names containing "Liberal Democrat"' do
        expect(described_class.new.call('Liberal Democrat')).to eq('Liberal Democratic Party')
        expect(described_class.new.call('Liberal Democratic Party')).to eq('Liberal Democratic Party')
      end

      it 'returns "Shooters, Fishers and Farmers Party" for names containing "Shooters, Fishers and Farmers"' do
        expect(described_class.new.call('Shooters, Fishers and Farmers')).to eq('Shooters, Fishers and Farmers Party')
      end

      it 'returns "Citizens Party" for names containing "Citizens Party" or "CEC"' do
        expect(described_class.new.call('Citizens Party')).to eq('Citizens Party')
        expect(described_class.new.call('CEC')).to eq('Citizens Party')
      end

      it 'returns "Sustainable Australia Party" for names containing "Sustainable Australia"' do
        expect(described_class.new.call('Sustainable Australia')).to eq('Sustainable Australia Party')
      end

      it 'returns "Centre Alliance" for names containing "Centre Alliance"' do
        expect(described_class.new.call('Centre Alliance')).to eq('Centre Alliance')
      end

      it 'returns "The Local Party of Australia" for names containing "The Local Party of Australia"' do
        expect(described_class.new.call('The Local Party of Australia')).to eq('The Local Party of Australia')
      end

      it 'returns "Katter Australia Party" for names containing "Katter Australia" or "KAP"' do
        expect(described_class.new.call('Katter Australia')).to eq('Katter Australia Party')
        expect(described_class.new.call('KAP')).to eq('Katter Australia Party')
      end

      it 'returns "Australian Conservatives" for names containing "Australian Conservatives"' do
        expect(described_class.new.call('Australian Conservatives')).to eq('Australian Conservatives')
      end

      it 'returns "Federal Independents" for names containing "Independent Fed"' do
        expect(described_class.new.call('Independent Fed')).to eq('Federal Independents')
      end

      it 'returns "Waringah Independents" for names containing "Warringah Independent" or "Waringah Independant"' do
        expect(described_class.new.call('Warringah Independent')).to eq('Waringah Independents')
        expect(described_class.new.call('Waringah Independant')).to eq('Waringah Independents')
      end

      it 'returns "Lambie Network" for names containing "Lambie"' do
        expect(described_class.new.call('Lambie')).to eq('Lambie Network')
      end

      it 'returns "United Australia Party" for names containing "United Australia Party" or "United Australia Federal"' do
        expect(described_class.new.call('United Australia Party')).to eq('United Australia Party')
        expect(described_class.new.call('United Australia Federal')).to eq('United Australia Party')
      end

      it 'returns "Pauline Hanson\'s One Nation" for names containing "Pauline Hanson" or "One Nation"' do
        expect(described_class.new.call('Pauline Hanson')).to eq("Pauline Hanson's One Nation")
        expect(described_class.new.call('One Nation')).to eq("Pauline Hanson's One Nation")
      end
    end

    context 'for liberal party' do
      it 'returns lib federal' do
        expect(described_class.new.call('Liberal Party Menzies Research Centre')).to eq('liberals (federal)')
      end
    end
  end
end

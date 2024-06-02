require 'rails_helper'
require 'spec_helper'

RSpec.describe RecordPerson, type: :service do

  let(:names_hash) do
    {
      "Kelly O'Dwyer" => "Kelly O'Dwyer",
      "Michael McCormack" => "Michael McCormack",
      "John Coote MP" => "John Coote",
      "Andrew D M Murray AM" => "Andrew D M Murray",
      "Arthur Sinodinos AO" => "Arthur Sinodinos",
    }
  end

  describe '#initialize' do
    it 'initializes with a name' do
      person = described_class.new('Test Name')
      expect(person.name).to eq('Test Name')
    end


  end

  describe '.call' do
    it 'creates or finds a group with the given name' do
      expect(Person).to receive(:find_or_create_by).with(name: 'Test Name')
      described_class.call('Test Name')
    end

    it 'uses the names from the hash', :aggregate_failures do
      names_hash.each do |name, expected|
        person = described_class.call(name)
        expect(person.name).to eq(expected)
      end
    end
  end
end
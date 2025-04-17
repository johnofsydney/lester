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
      "Hon Paul Smith" => "Paul Smith",
      "Jimmy Hon" => "Jimmy Hon",
      "The Hon. Peter Francis Watkins" => "Peter Francis Watkins",
      "Hon Catherine King" => "Catherine King",
      "The Hon Robert Borbidge" => "Robert Borbidge",
      "The Hon Leslie Gladys Williams" => "Leslie Gladys Williams",
      "Grusovin, The Hon. Deirdre Mary" => "Deirdre Mary Grusovin",
    }
  end

  describe '#initialize' do
    it 'initializes with a name' do
      person = described_class.new('Test Name')
      expect(person.name).to eq('Test Name')
    end
  end

  # TODO: Make the other similar tests use this format which reports the failing name
  describe '.call' do
    before do
      allow(Person).to receive(:find_or_create_by).and_call_original
    end

    it 'creates or finds a group with the given name' do
      described_class.call('Test Name')
      expect(Person).to have_received(:find_or_create_by).with(name: 'Test Name')
    end

    it 'uses the names from the hash', :aggregate_failures do
      names_hash.each do |name, expected|
        person = described_class.call(name)
        expect(person.name).to eq(expected)
      end
    end
  end
end
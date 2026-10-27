require 'rails_helper'

RSpec.describe Nodes::NameCapitalizer do
  describe '.capitalize' do
    it 'upcases short words that look like acronyms' do
      expect(described_class.capitalize('abc pty ltd')).to eq('ABC Pty Ltd')
    end

    it 'does not upcase words in the exceptions list' do
      expect(described_class.capitalize('the fund')).to eq('The Fund')
    end

    it 'raises when given a blank name' do
      expect { described_class.capitalize('') }.to raise_error(RuntimeError)
    end

    it 'returns nil for non-string input' do
      expect(described_class.capitalize(123)).to be_nil
    end
  end

  describe '.capitalize_for' do
    it 'title-cases a Person name without upcasing short words' do
      expect(described_class.capitalize_for('Person', 'adam benson')).to eq('Adam Benson')
      expect(described_class.capitalize_for('Person', 'aiden may')).to eq('Aiden May')
    end

    it 'runs a Group name through the acronym-aware capitalizer' do
      expect(described_class.capitalize_for('Group', 'abc pty ltd')).to eq('ABC Pty Ltd')
    end

    it 'returns nil for a blank name' do
      expect(described_class.capitalize_for('Person', nil)).to be_nil
      expect(described_class.capitalize_for('Person', '')).to be_nil
    end
  end
end

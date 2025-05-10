require 'rails_helper'
require 'spec_helper'

RSpec.describe RecordPerson, type: :service do
  describe '#initialize' do
    it 'initializes with a name' do
      person = described_class.new('Test Name')
      expect(person.name).to eq('Test Name')
    end
  end

  describe '.call' do
    before do
      allow(Person).to receive(:find_or_create_by).and_call_original
    end

    it 'creates or finds a group with the given name' do
      described_class.call('Test Name')
      expect(Person).to have_received(:find_or_create_by).with(name: 'Test Name')
    end

    it 'leaves apostrophe in name' do
      expect(described_class.call("Kelly O'Dwyer").name).to eq("Kelly O'Dwyer")
    end

    it 'capitalizes McName ok' do
      expect(described_class.call('Michael McCormack').name).to eq('Michael McCormack')
    end

    it 'removes trailing MP from name' do
      expect(described_class.call('John Coote MP').name).to eq('John Coote')
    end

    it 'removes trailing AM from name' do
      expect(described_class.call('Andrew D M Murray AM').name).to eq('Andrew D M Murray')
    end

    it 'removes trailing AO from name' do
      expect(described_class.call('Arthur Sinodinos AO').name).to eq('Arthur Sinodinos')
    end

    it 'removes prefix Hon from name' do
      expect(described_class.call('Hon Paul Smith').name).to eq('Paul Smith')
    end

    it 'leaves the surname Hon in name' do
      expect(described_class.call('Jimmy Hon').name).to eq('Jimmy Hon')
    end

    it 'removes prefix The Hon. from name' do
      expect(described_class.call('The Hon. Peter Francis Watkins').name).to eq('Peter Francis Watkins')
    end

    it 'removes prefix Hon from name' do
      expect(described_class.call('Hon Catherine King').name).to eq('Catherine King')
    end

    it 'removes prefix The Hon from name' do
      expect(described_class.call('The Hon Robert Borbidge').name).to eq('Robert Borbidge')
    end

    it 'removes prefix Hon. from name' do
      expect(described_class.call('Grusovin, The Hon. Deirdre Mary').name).to eq('Deirdre Mary Grusovin')
    end

    describe ' specific people known by shorter or longer names' do
      it 'returns David Pocock for David Pocock' do
        expect(described_class.call('David Pocock').name).to eq('David Pocock')
      end

      it 'returns Nicholas Fairfax for Nicholas John Fairfax' do
        expect(described_class.call('Nicholas John Fairfax').name).to eq('Nicholas Fairfax')
      end

      it 'returns Kylea Tink for Kylea Tink' do
        expect(described_class.call('Kylea Tink').name).to eq('Kylea Tink')
      end

      it 'returns Allegra Spender for Allegra Spender' do
        expect(described_class.call('Allegra Spender').name).to eq('Allegra Spender')
      end

      it 'returns Brian Mitchell for Brian Mitchell' do
        expect(described_class.call('Brian Mitchell').name).to eq('Brian Mitchell')
      end

      it 'returns Carina Garland for Carina Garland' do
        expect(described_class.call('Carina Garland').name).to eq('Carina Garland')
      end

      it 'returns Monique Ryan for Monique Ryan' do
        expect(described_class.call('Monique Ryan').name).to eq('Monique Ryan')
      end

      it 'returns Kate Chaney for Katherine Chaney' do
        expect(described_class.call('Katherine Chaney').name).to eq('Kate Chaney')
      end

      it 'returns Sophie Scamps for Sophie Scamps' do
        expect(described_class.call('Sophie Scamps').name).to eq('Sophie Scamps')
      end

      it 'returns Andrew Wilkie for Andrew Wilkie' do
        expect(described_class.call('Andrew Wilkie').name).to eq('Andrew Wilkie')
      end

      it 'returns Tony Windsor for Antony Harold Curties Windsor' do
        expect(described_class.call('Antony Harold Curties Windsor').name).to eq('Tony Windsor')
      end

      it 'returns Bob Katter for Robert Katter' do
        expect(described_class.call('Robert Katter').name).to eq('Bob Katter')
      end

      it 'returns Malcolm Turnbull for Malcolm Turnbull' do
        expect(described_class.call('Malcolm Turnbull').name).to eq('Malcolm Turnbull')
      end

      it 'returns Helen Haines for Helen Haines' do
        expect(described_class.call('Helen Haines').name).to eq('Helen Haines')
      end

      it 'returns Greg Cheesman for Greg Cheesman' do
        expect(described_class.call('Greg Cheesman').name).to eq('Greg Cheesman')
      end

      it 'returns Jacinta Nampijinpa Price for Jacinta Price' do
        expect(described_class.call('Jacinta Price').name).to eq('Jacinta Nampijinpa Price')
      end

      it 'returns Kerryn Phelps for Kerryn Phelps' do
        expect(described_class.call('Kerryn Phelps').name).to eq('Kerryn Phelps')
      end

      it 'returns Mike Cannon Brookes for Mike Cannon Brookes' do
        expect(described_class.call('Mike Cannon Brookes').name).to eq('Mike Cannon Brookes')
      end

      it 'returns Fraser Anning for Fraser Anning' do
        expect(described_class.call('Fraser Anning').name).to eq('Fraser Anning')
      end
    end
  end
end
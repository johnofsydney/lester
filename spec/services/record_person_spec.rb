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
      expect(described_class.call("Kelly O'Dwyer").name).to eq("kelly o'dwyer")
    end

    it 'capitalizes McName ok' do
      expect(described_class.call('Michael McCormack').name).to eq('michael mccormack')
    end

    it 'removes trailing MP from name' do
      expect(described_class.call('John Coote MP').name).to eq('john coote')
    end

    it 'removes trailing AM from name' do
      expect(described_class.call('Andrew D M Murray AM').name).to eq('andrew d m murray')
    end

    it 'removes trailing AO from name' do
      expect(described_class.call('Arthur Sinodinos AO').name).to eq('arthur sinodinos')
    end

    it 'removes prefix Hon from name' do
      expect(described_class.call('Hon Paul Smith').name).to eq('paul smith')
    end

    it 'leaves the surname Hon in name' do
      expect(described_class.call('Jimmy Hon').name).to eq('jimmy hon')
    end

    it 'removes prefix The Hon. from name' do
      expect(described_class.call('The Hon. Peter Francis Watkins').name).to eq('peter francis watkins')
    end

    it 'removes prefix Hon from name' do
      expect(described_class.call('Hon Catherine King').name).to eq('catherine king')
    end

    it 'removes prefix The Hon from name' do
      expect(described_class.call('The Hon Robert Borbidge').name).to eq('robert borbidge')
    end

    it 'removes prefix Hon. from name' do
      expect(described_class.call('Grusovin, The Hon. Deirdre Mary').name).to eq('deirdre mary grusovin')
    end

    describe ' specific people known by shorter or longer names' do
      it 'returns David Pocock for David Pocock' do
        expect(described_class.call('David Pocock').name).to eq('david pocock')
      end

      it 'returns Nicholas Fairfax for Nicholas John Fairfax' do
        expect(described_class.call('Nicholas John Fairfax').name).to eq('nicholas fairfax')
      end

      it 'returns Kylea Tink for Kylea Tink' do
        expect(described_class.call('Kylea Tink').name).to eq('kylea tink')
      end

      it 'returns Allegra Spender for Allegra Spender' do
        expect(described_class.call('Allegra Spender').name).to eq('allegra spender')
      end

      it 'returns Brian Mitchell for Brian Mitchell' do
        expect(described_class.call('Brian Mitchell').name).to eq('brian mitchell')
      end

      it 'returns Carina Garland for Carina Garland' do
        expect(described_class.call('Carina Garland').name).to eq('carina garland')
      end

      it 'returns Monique Ryan for Monique Ryan' do
        expect(described_class.call('Monique Ryan').name).to eq('monique ryan')
      end

      it 'returns Kate Chaney for Katherine Chaney' do
        expect(described_class.call('Katherine Chaney').name).to eq('kate chaney')
      end

      it 'returns Sophie Scamps for Sophie Scamps' do
        expect(described_class.call('Sophie Scamps').name).to eq('sophie scamps')
      end

      it 'returns Andrew Wilkie for Andrew Wilkie' do
        expect(described_class.call('Andrew Wilkie').name).to eq('andrew wilkie')
      end

      it 'returns Tony Windsor for Antony Harold Curties Windsor' do
        expect(described_class.call('Antony Harold Curties Windsor').name).to eq('tony windsor')
      end

      it 'returns Bob Katter for Robert Katter' do
        expect(described_class.call('Robert Katter').name).to eq('bob katter')
      end

      it 'returns Malcolm Turnbull for Malcolm Turnbull' do
        expect(described_class.call('Malcolm Turnbull').name).to eq('malcolm turnbull')
      end

      it 'returns Helen Haines for Helen Haines' do
        expect(described_class.call('Helen Haines').name).to eq('helen haines')
      end

      it 'returns Greg Cheesman for Greg Cheesman' do
        expect(described_class.call('Greg Cheesman').name).to eq('greg cheesman')
      end

      it 'returns Jacinta Nampijinpa Price for Jacinta Price' do
        expect(described_class.call('Jacinta Price').name).to eq('jacinta nampijinpa price')
      end

      it 'returns Kerryn Phelps for Kerryn Phelps' do
        expect(described_class.call('Kerryn Phelps').name).to eq('kerryn phelps')
      end

      it 'returns Mike Cannon Brookes for Mike Cannon Brookes' do
        expect(described_class.call('Mike Cannon Brookes').name).to eq('mike cannon brookes')
      end

      it 'returns Fraser Anning for Fraser Anning' do
        expect(described_class.call('Fraser Anning').name).to eq('fraser anning')
      end
    end
  end
end
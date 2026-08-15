require 'rails_helper'

RSpec.describe Record::SavingHelpers do
  let(:includer) do
    Class.new do
      include Record::SavingHelpers

      attr_reader :name

      def initialize(name:)
        @name = name
      end
    end.new(name: 'Acme Foundation')
  end

  describe '#save_inside_advisory_lock!' do
    context 'when no block is given' do
      it 'saves and returns the entity' do
        group = Group.new(name: 'Acme Foundation')

        expect { includer.save_inside_advisory_lock!(group) }.to change(Group, :count).by(1)
        expect(group).to be_persisted
      end
    end

    context 'when a block is given and it finds no existing record' do
      it 'saves and returns the new entity' do
        group = Group.new(name: 'Acme Foundation')

        result = includer.save_inside_advisory_lock!(group) { Group.find_by(name: 'Acme Foundation') }

        expect(result).to eq(group)
        expect(result).to be_persisted
      end
    end

    context 'when a block is given and it finds an existing record' do
      it 'does not save the new entity and returns the existing one instead' do
        existing = FactoryBot.create(:group, name: 'Acme Foundation')
        group = Group.new(name: 'Acme Foundation')

        result = nil
        expect do
          result = includer.save_inside_advisory_lock!(group) { Group.find_by(name: 'Acme Foundation') }
        end.not_to change(Group, :count)

        expect(result).to eq(existing)
        expect(group).not_to be_persisted
      end
    end
  end

  describe 'concurrent calls for the same name (TOCTOU race)' do
    self.use_transactional_tests = false

    after do
      Person.where('name ILIKE ?', 'Concurrent Person%').destroy_all
    end

    it 'only ever creates one Person for the same name' do
      name = "Concurrent Person #{SecureRandom.hex(4)}"

      threads = Array.new(5) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection do
            People::RecordPerson.call(name)
          end
        end
      end
      threads.each(&:join)

      expect(Person.where(name: name.downcase).count).to eq(1)
    end
  end
end

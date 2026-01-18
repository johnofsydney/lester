class People::DeleteDuplicates
  def self.call
    new.call
  end

  def call
    duplicates.each do |name, ids|
      Rails.logger.info("Deleting one duplicate person with name: #{name} from ids: #{ids.join(', ')}")

      p1_id = ids.first
      p2_id = ids.last

      p1 = Person.find(p1_id)
      p2 = Person.find(p2_id)

      p1.merge!(p2)
    end
  end

  def duplicates
    Person.group('UPPER(name)').having('COUNT(*) > 1').pluck('UPPER(name)', 'ARRAY_AGG(id)')
  end
end

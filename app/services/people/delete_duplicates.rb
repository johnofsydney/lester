class People::DeleteDuplicates
  def self.call(dry_run: true, scope: Person.all)
    new.call(dry_run:, scope:)
  end

  def call(dry_run: true, scope: Person.all)
    duplicates(scope).each do |name, ids|
      keeper_id, *duplicate_ids = ids

      Rails.logger.info(
        "#{dry_run ? '[DRY RUN] Would merge' : 'Merging'} #{duplicate_ids.size} duplicate " \
        "people named '#{name}' into ##{keeper_id} (ids: #{duplicate_ids.join(', ')})"
      )

      next if dry_run

      keeper = Person.find(keeper_id)
      duplicate_ids.each { |duplicate_id| keeper.merge!(Person.find(duplicate_id)) }
    end
  end

  def duplicates(scope = Person.all)
    scope.group('UPPER(name)').having('COUNT(*) > 1').pluck('UPPER(name)', Arel.sql('ARRAY_AGG(id ORDER BY id)'))
  end
end

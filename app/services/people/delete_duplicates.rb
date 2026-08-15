class People::DeleteDuplicates
  def self.call(scope:, dry_run: true)
    new.call(scope:, dry_run:)
  end

  def call(scope:, dry_run: true)
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

  def duplicates(scope)
    scope.group('UPPER(name)').having('COUNT(*) > 1').pluck('UPPER(name)', Arel.sql('ARRAY_AGG(id ORDER BY id)'))
  end

  # The ids of every duplicate within `scope`, excluding each name-group's keeper
  # (the lowest id, which `#call` would merge everything else into).
  def duplicate_ids(scope)
    duplicates(scope).flat_map { |_name, ids| ids.drop(1) }
  end

  # The lowest-id same-name Person within `scope` that is compatible with `person`, i.e.
  # the record `person` would be folded into by `#call`. Scoping matters: without it, a
  # duplicate could match a same-name Person outside the intended subgraph (e.g. an
  # unrelated AEC donor). When a block is given, candidates are further filtered through
  # it (yielded `person, candidate`) for callers whose notion of "safe to merge" needs
  # more than an exact name match - the first candidate id, in order, for which it
  # returns true wins.
  def keeper_for(person, scope:)
    candidates = scope.where('UPPER(name) = ?', person.name.upcase).where.not(id: person.id).order(:id)
    return candidates.first unless block_given?

    candidates.find { |candidate| yield(person, candidate) }
  end
end

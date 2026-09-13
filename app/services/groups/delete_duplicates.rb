class Groups::DeleteDuplicates
  def self.call(dry_run: true)
    new.call(dry_run:)
  end

  def call(dry_run: true)
    duplicates.each do |name, ids|
      keeper_id, *duplicate_ids = ids

      Rails.logger.info(
        "#{dry_run ? '[DRY RUN] Would merge' : 'Merging'} #{duplicate_ids.size} duplicate " \
        "groups named '#{name}' into ##{keeper_id} (ids: #{duplicate_ids.join(', ')})"
      )

      next if dry_run

      keeper = Group.find(keeper_id)
      duplicate_ids.each { |duplicate_id| keeper.merge!(Group.find(duplicate_id)) }
    end
  end

  def duplicates
    Group.group('UPPER(name)').having('COUNT(*) > 1').pluck('UPPER(name)', Arel.sql('ARRAY_AGG(id ORDER BY id)'))
  end

  # The ids of every duplicate Group, excluding each name-group's keeper (the lowest id,
  # which `#call` would merge everything else into).
  def duplicate_ids
    duplicates.flat_map { |_name, ids| ids.drop(1) }
  end

  # The lowest-id same-name Group that `group` would be folded into by `#call`. When a
  # block is given, candidates are further filtered through it (yielded `group, candidate`)
  # for callers whose notion of "safe to merge" needs more than an exact name match - the
  # first candidate id, in order, for which it returns true wins.
  def keeper_for(group)
    candidates = Group.where('UPPER(name) = ?', group.name.upcase).where.not(id: group.id).order(:id)
    return candidates.first unless block_given?

    candidates.find { |candidate| yield(group, candidate) }
  end
end

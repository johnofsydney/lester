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
end

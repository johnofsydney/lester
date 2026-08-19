namespace :lester do
  desc 'Find Duplicates'
  task find_duplicates: :environment do
    group_duplicates = Groups::DeleteDuplicates.new.duplicates
    person_duplicates = People::DeleteDuplicates.new.duplicates

    p 'People duplicates (name => [ids]):', person_duplicates
    p 'Group duplicates (name => [ids]):', group_duplicates
  end

  desc 'Potential People in the Groups Table'
  task potential_people: :environment do
    potential_people = Group.order(:name).pluck(:name).filter do |name|
      service = RecordPersonOrGroup.new(name)
      service.person_or_group == 'person'
    end

    p potential_people
  end

  desc 'Find Groups with No People Members'
  task groups_without_people: :environment do
    groups_without_people = Group.where.not(
      id: Membership.where(member_type: 'Person').select(:group_id)
    )

    puts "Found #{groups_without_people.count} groups with no people members:"
    puts '=' * 80

    groups_without_people.each do |group|
      puts "ID: #{group.id} | Name: #{group.name} | Category: #{group.category}"
    end

    puts '=' * 80
    puts "Total: #{groups_without_people.count} groups"
  end

  desc 'Find Groups with No Group Members'
  task groups_without_groups: :environment do
    groups_without_groups = Group.where.not(
      id: Membership.where(member_type: 'Group').select(:group_id)
    )

    puts "Found #{groups_without_groups.count} groups with no group members:"
    puts '=' * 80

    groups_without_groups.each do |group|
      puts "ID: #{group.id} | Name: #{group.name} | Category: #{group.category}"
    end

    puts '=' * 80
    puts "Total: #{groups_without_groups.count} groups"
  end

  desc 'Find Groups with No Transfers'
  task groups_without_transfers: :environment do
    groups_without_transfers = Group.left_outer_joins(:incoming_transfers, :outgoing_transfers)
                                    .where(incoming_transfers: { id: nil })
                                    .where(outgoing_transfers: { id: nil })
                                    .distinct

    puts "Found #{groups_without_transfers.count} groups with no incoming or outgoing transfers:"
    puts '=' * 80

    groups_without_transfers.each do |group|
      puts "ID: #{group.id} | Name: #{group.name} | Category: #{group.category}"
    end

    puts '=' * 80
    puts "Total: #{groups_without_transfers.count} groups"
  end

  desc 'Backfill Null Data in Transfers'
  task backfill_transfer_data: :environment do
    null_count = Transfer.where(data: nil).count
    puts "Found #{null_count} transfers with null data"

    if null_count.positive?
      Transfer.where(data: nil).update_all(data: {})
      puts "Backfilled #{null_count} transfers with empty data hash"
    else
      puts 'No transfers need backfilling'
    end
  end

  desc 'Copy category into fine grained category for Individual Transactions'
  task copy_category_to_fine_grained: :environment do
    count = 0
    IndividualTransaction.where.not(category: nil)
                         .where(fine_grained_transaction_category_id: nil)
                         .find_each do |transaction|
      category_name = transaction.category
      fine_grained_transaction_category = FineGrainedTransactionCategory.find_or_create_by!(name: category_name)
      transaction.update!(fine_grained_transaction_category:)
      count += 1
      puts "Updated Individual Transaction ID #{transaction.id} with fine grained category '#{category_name}'"
    end

    puts "Updated #{count} Individual Transactions with fine grained categories."
  end

  desc 'Copy Category into tags for Groups'
  task copy_category_to_tags: :environment do
    count = 0
    Group.where(category: true).where.not(name: nil).find_each do |group|
      name = group.name
      group.update(name: "#{name} (Category)")
      tag = Tag.find_or_create_by!(name:)

      Membership.where(group:).update_all(group_id: tag.id)
      group.destroy
      count += 1
      puts "Promoted group #{name} to tag and updated memberships for Group ID #{group.id}"
    end

    puts "Updated #{count} Groups with tags based on their category names."
  end

  desc 'Deduplicate transfers for unique natural key index'
  task dedupe_transfers_natural_key: :environment do
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'true'))

    grouped = Transfer.group(
      :giver_type,
      :giver_id,
      :taker_type,
      :taker_id,
      :effective_date,
      :transfer_type,
      :evidence
    ).having('COUNT(*) > 1')

    duplicate_groups = grouped.count

    if duplicate_groups.empty?
      puts 'No duplicate transfers found for natural key.'
      next
    end

    puts "Found #{duplicate_groups.size} duplicate transfer key groups."
    puts "DRY_RUN=#{dry_run}"

    groups_processed = 0
    transfers_deleted = 0
    transactions_relinked = 0

    duplicate_groups.each_key do |key|
      giver_type, giver_id, taker_type, taker_id, effective_date, transfer_type, evidence = key

      transfers = Transfer.where(
        giver_type:,
        giver_id:,
        taker_type:,
        taker_id:,
        effective_date:,
        transfer_type:,
        evidence:
      ).order(:id)

      keeper = transfers.first
      duplicates = transfers.where.not(id: keeper.id)
      duplicate_ids = duplicates.pluck(:id)
      next if duplicate_ids.empty?

      amount_values = transfers.reorder(nil).distinct.pluck(:amount)

      puts "Warning: transfer amount differs in group; keeping amount from Transfer ##{keeper.id}. IDs=#{transfers.pluck(:id).join(',')}" if amount_values.size > 1

      group_relinked = IndividualTransaction.where(transfer_id: duplicate_ids).count

      unless dry_run
        Transfer.transaction do
          IndividualTransaction.where(transfer_id: duplicate_ids).update_all(transfer_id: keeper.id)
          Transfer.where(id: duplicate_ids).delete_all
        end
      end

      groups_processed += 1
      transfers_deleted += duplicate_ids.size
      transactions_relinked += group_relinked

      puts "Processed group #{groups_processed}: keeper=#{keeper.id}, duplicates=#{duplicate_ids.size}, relinked_individual_transactions=#{group_relinked}"
    end

    puts 'Done.'
    puts "Groups processed: #{groups_processed}"
    puts "Transfers deleted#{dry_run ? ' (would delete)' : ''}: #{transfers_deleted}"
    puts "Individual transactions relinked#{dry_run ? ' (would relink)' : ''}: #{transactions_relinked}"
    puts 'Run with DRY_RUN=false to apply changes.' if dry_run
  end

  desc 'Delete legacy Parliament/Federal Branch Memberships and Positions superseded by OpenAustralia Interpretation'
  task cleanup_legacy_politician_memberships: :environment do
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'true'))

    federal_branch_group_names = OpenAustralia::Interpretation::ResolvePartyAffiliations::MAJOR_PARTY_FAMILIES
                                 .map(&:first).uniq
                                 .map { |family| Group::NAMES.send(family).federal }
    federal_branch_group_ids = Group.where(name: federal_branch_group_names).pluck(:id)
    legacy_group_ids = ([Group.federal_parliament.id] + federal_branch_group_ids).uniq

    puts "DRY_RUN=#{dry_run}"

    legacy_group_ids.each do |group_id|
      group = Group.find(group_id)
      membership_ids = Membership.where(group_id: group_id).pluck(:id)
      position_count = Position.where(membership_id: membership_ids).count

      puts "Group ##{group_id} (#{group.name}): #{membership_ids.size} memberships, #{position_count} positions#{dry_run ? ' (would delete)' : ''}"
    end

    if dry_run
      puts 'Run with DRY_RUN=false to apply changes.'
      next
    end

    membership_ids = Membership.where(group_id: legacy_group_ids).pluck(:id)
    positions_deleted = Position.where(membership_id: membership_ids).delete_all
    memberships_deleted = Membership.where(id: membership_ids).delete_all

    puts "Deleted #{memberships_deleted} memberships and #{positions_deleted} positions across #{legacy_group_ids.size} groups."
  end

  desc 'Delete Memberships whose polymorphic member reference points at a deleted Person/Group'
  task cleanup_orphaned_memberships: :environment do
    dry_run = ActiveModel::Type::Boolean.new.cast(ENV.fetch('DRY_RUN', 'true'))

    orphaned_by_type = %w[Person Group].index_with do |member_type|
      klass = member_type.constantize
      Membership.where(member_type: member_type)
                .where.not(member_id: klass.select(:id))
                .pluck(:id)
    end

    puts "DRY_RUN=#{dry_run}"
    orphaned_by_type.each { |member_type, ids| puts "#{member_type}: #{ids.size} orphaned memberships#{dry_run ? ' (would delete)' : ''}" }

    if dry_run
      puts 'Run with DRY_RUN=false to apply changes.'
      next
    end

    orphaned_ids = orphaned_by_type.values.flatten
    positions_deleted = Position.where(membership_id: orphaned_ids).delete_all
    memberships_deleted = Membership.where(id: orphaned_ids).delete_all

    puts "Deleted #{memberships_deleted} orphaned memberships and #{positions_deleted} positions."
  end

  desc 'Run OpenAustralia Interpretation (RecordMembershipsAndPositions) for every already-ingested politician'
  task record_politician_memberships_and_positions: :environment do
    # `where.not(open_australia_data: [])` is a Rails gotcha for jsonb columns: an empty array
    # value is treated as an empty IN-list, so `.not` on it matches everyone (`WHERE 1=1`), not
    # "not equal to []". Comparing against the serialized JSON string is what actually excludes
    # the column's `[]` default.
    people = Person.where('open_australia_data != ?', [].to_json)
    puts "Found #{people.count} people with OpenAustralia data to interpret."

    membership_count_before = Membership.count
    position_count_before = Position.count
    processed = 0
    errors = []

    people.find_each do |person|
      OpenAustralia::Interpretation::RecordMembershipsAndPositions.call(person: person)
      processed += 1
    rescue StandardError => e
      errors << "Person ##{person.id} (#{person.name}): #{e.message}"
    end

    puts "Processed #{processed} people."
    puts "Memberships: #{Membership.count - membership_count_before} net new (#{Membership.count} total)."
    puts "Positions: #{Position.count - position_count_before} net new (#{Position.count} total)."

    if errors.any?
      puts "#{errors.size} errors:"
      errors.each { |error| puts "  #{error}" }
    else
      puts 'No errors.'
    end
  end
end
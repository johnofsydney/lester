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
end
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

  desc 'Backfill missing categories for Aus Tender Individual Transactions : Recruitment and Labour Hire'
  task backfill_recruitment_category: :environment do
    count = 0

    # This is the JTD Category we want to backfill for
    CATEGORY = 'Recruitment and Labour Hire'.freeze # rubocop:disable Lint/ConstantDefinitionInBlock

    puts "Starting backfill of '#{CATEGORY}' category for relevant Individual Transactions..."

    # This is a list of all of the categories that appear on the Individual Transactions that we want to backfill for.
    # We need to get the keys for these categories from the MapTransactionCategories class
    category_list = MapTransactionCategories::ALL_CATEGORIES.select { |_k, v| v == CATEGORY }.keys

    Transfer.joins(:individual_transactions)
            .where(transfer_type: 'Government Contract(s)')
            .where(individual_transactions: { category: category_list })
            .select('DISTINCT ON (transfers.taker_type, transfers.taker_id) transfers.*')
            .each do |transfer|
        taker = transfer.taker
        category = Group.find_or_create_by!(name: CATEGORY, category: true)

        if taker.is_group? && category.present?
          taker.add_to_category(category_group: category)
          count += 1
          puts "Added category to Group ID #{taker.id} for Transfer ID #{transfer.id}"
        end
    rescue StandardError => e
        puts "Error processing Transfer ID #{transfer.id}: #{e.message}"
    end

    puts "Processed #{count} transfers and backfilled '#{CATEGORY}' category for relevant Groups."
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
      fine_grained_category = FineGrainedTransactionCategory.find_or_create_by!(name: category_name)
      transaction.update!(fine_grained_transaction_category: fine_grained_category)
      count += 1
      puts "Updated Individual Transaction ID #{transaction.id} with fine grained category '#{category_name}'"
    end

    puts "Updated #{count} Individual Transactions with fine grained categories."
  end
end
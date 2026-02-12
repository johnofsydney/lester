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

    puts "Starting backfill of 'Recruitment and Labour Hire' category for relevant Individual Transactions..."

    Transfer.joins(:individual_transactions)
            .where(transfer_type: 'Government Contract(s)')
            .where(individual_transactions: { category: ['Temporary personnel services', 'Personnel recruitment'] })
            .select('DISTINCT ON (transfers.taker_type, transfers.taker_id) transfers.*')
            .each do |transfer|
        taker = transfer.taker
        category = Group.find_or_create_by!(name: 'Recruitment and Labour Hire', category: true)

        if taker.is_group? && category.present?
          taker.add_category(category_group: category)
          count += 1
          puts "Added category to Group ID #{taker.id} for Transfer ID #{transfer.id}"
        end
    rescue StandardError => e
        puts "Error processing Transfer ID #{transfer.id}: #{e.message}"
    end
  end

  # desc 'Clear Cache for Network Graph and Count'
  # task clear_cache: :environment do
  #   Group.update_all(cached_data: {})
  #   Person.update_all(cached_data: {})

  # end

  # desc 'Back Fill all the Aus Tender Contracts going back to 2018-01-01'
  # # This task can be deleted when completed
  # task backfill_contracts: :environment do
  #   start_date = Date.new(2018, 1, 1)

  #   backfill = ContractBackfill.first_or_create!(last_processed_date: start_date)

  #   puts "Backfill starting at #{backfill.last_processed_date}"

  #   BackfillContractsMasterJob.perform_async(backfill.last_processed_date.to_s)
  # end

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
end
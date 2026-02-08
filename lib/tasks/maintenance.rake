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
end
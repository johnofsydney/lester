namespace :lester do
  desc 'Destroy All Records'
  task destroy_all: :environment do
    Transfer.destroy_all
    Membership.destroy_all
    Group.destroy_all
    Person.destroy_all

    ActiveRecord::Base.connection.reset_pk_sequence!('transfers')
    ActiveRecord::Base.connection.reset_pk_sequence!('memberships')
    ActiveRecord::Base.connection.reset_pk_sequence!('groups')
    ActiveRecord::Base.connection.reset_pk_sequence!('people')
  end

  desc "Destroy all records and re-populate"
  task populate: :environment do

    Transfer.destroy_all
    Position.destroy_all
    Membership.destroy_all
    Group.destroy_all
    Person.destroy_all

    ActiveRecord::Base.connection.reset_pk_sequence!('transfers')
    ActiveRecord::Base.connection.reset_pk_sequence!('positions')
    ActiveRecord::Base.connection.reset_pk_sequence!('memberships')
    ActiveRecord::Base.connection.reset_pk_sequence!('groups')
    ActiveRecord::Base.connection.reset_pk_sequence!('people')

    donation_files = [
      # 'csv_data/Annual_Donations_Made_2018.csv',
      # 'csv_data/Annual_Donations_Made_2019.csv',
      # 'csv_data/Annual_Donations_Made_2020.csv',
      # 'csv_data/Annual_Donations_Made_2021.csv',
      # 'csv_data/Annual_Donations_Made_2022.csv',
      'csv_data/Annual_Donations_Made_2023.csv',
    ]

    donation_files.each do |file|
      FileIngestor.annual_donor_ingest(file)
    end

    federal_parliamentarians = [
      'csv_data/wiki_feds_current_mps_cleaned.csv',
      # 'csv_data/wiki_feds_current_senators_cleaned.csv',
      # 'csv_data/wiki_feds_ending_2019_cleaned.csv',
      # 'csv_data/wiki_feds_ending_2022_cleaned.csv',
      # 'csv_data/wiki_feds_senators_ending_2019_cleaned.csv',
      'csv_data/wiki_feds_senators_ending_2022_cleaned.csv'
    ]

    federal_parliamentarians.each do |file|
      FileIngestor.federal_parliamentarians_upload(file)
    end

    federal_ministries = [
      # 'csv_data/ministries_morrison.csv',
      # 'csv_data/ministries_turnbull.csv',
    ]

    federal_ministries.each do |file|
      FileIngestor.ministries_upload(file)
    end

    FileIngestor.general_upload('csv_data/other_people_groups_positions.csv')

    FileIngestor.affiliations_upload('csv_data/affiliations.csv')
    FileIngestor.transfers_upload('csv_data/other_transfers.csv')






    # # ALP Senators, State and past members
    # Membership.find_or_create_by(group: labor_federal, member: kevin_rudd, start_date: Date.new(2006, 12, 4), end_date: Date.new(2010, 6, 24))
    # Membership.find_or_create_by(group: labor_federal, member: mark_latham, start_date: Date.new(2003, 12, 2), end_date: Date.new(2005, 1, 18))
    # Membership.find_or_create_by(group: labor_nsw, member: ian_macdonald, start_date: Date.new(1988, 3, 19), end_date: Date.new(2010, 6, 7))
    # Membership.find_or_create_by(group: labor_nsw, member: eddie_obeid, start_date: Date.new(1991, 5, 6), end_date: Date.new(2011, 5, 6))


    # Membership.find_or_create_by(group: one_nation, member: mark_latham, start_date: Date.new(2018, 11, 15), end_date: Date.new(2022, 6, 30))

  end
end
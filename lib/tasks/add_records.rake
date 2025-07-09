namespace :lester do
  desc 'Augment'
  task augment: :environment do

    # NSW Parliamentarians from a list downloaded from
    # https://www.parliament.nsw.gov.au/members/downloadables/Pages/downloadable-lists.aspx
    # FileIngestor.nsw_parliamentarians_upload('csv_data/nsw_parliamentarians.csv')

    # From a file created and maintained by me, whenever noteworthy people or groups appear in the news
    # COMPLETE
    # FileIngestor.general_upload('csv_data/other_people_groups_positions-2024-09-13.csv')
    # FileIngestor.general_upload('csv_data/other_people_groups_positions-2024-11-13.csv')
    # FileIngestor.general_upload('csv_data/other_people_groups_positions-2024-11-14.csv')
    # FileIngestor.general_upload('csv_data/other_people_groups_positions-2025-01-15.csv')
    # FileIngestor.general_upload('csv_data/other_people_groups_positions-2025-02-18.csv')
    # FileIngestor.general_upload('csv_data/other_people_groups_positions-2025-03-14.csv')
    # FileIngestor.general_upload('csv_data/other_people_groups_positions-2025-03-15.csv')
    FileIngestor.general_upload(file: 'csv_data/other_people_groups_positions-2025-04-21.csv')

    # From a file created and maintained by me, linking groups to groups, whenever information comes to light
    # COMPLETE
    # FileIngestor.affiliations_upload('csv_data/affiliations-2024-09-18.csv')
    # FileIngestor.affiliations_upload('csv_data/affiliations-2024-10-23.csv') - affiliations mostly for Australian Energy Producers
    # FileIngestor.affiliations_upload('csv_data/affiliations-2024-10-29.csv') # adding more categories
    # FileIngestor.affiliations_upload('csv_data/affiliations-2024-11-15.csv') # adding more categories
    # FileIngestor.affiliations_upload('csv_data/lobbyists_and_clients_cleaned_2025-01-02.csv') # clients of lobbyists from the AG register
    # FileIngestor.affiliations_upload('csv_data/affiliations-2025-03-14.csv') # adding more categories
    # FileIngestor.affiliations_upload('csv_data/affiliations-2025-03-15.csv')
    FileIngestor.affiliations_upload('csv_data/affiliations-2025-03-16.csv')

    # This is a reminder, to add more info on ministries.
    federal_ministries = [
      # 'csv_data/ministries_albanese.csv',
    ]

    # using data sourced from wikipedia
    federal_ministries.each do |file|
      # FileIngestor.ministries_upload(file)
    end

    lobbyists = [
      # 'csv_data/lobbyists_2024-11-04.csv',
      # 'csv_data/lobyyists_2024-11-05.csv',
    ]

    lobbyists.each do |file|
      # FileIngestor.lobbyists_upload(file)
    end

    annual_donation_files = [
    #     'csv_data/Annual_Donations_Made_2018.csv',
    #     'csv_data/Annual_Donations_Made_2019.csv',
    #     'csv_data/Annual_Donations_Made_2020.csv',
    #     'csv_data/Annual_Donations_Made_2021.csv',
    #     'csv_data/Annual_Donations_Made_2022.csv',
    #     'csv_data/Annual_Donations_Made_2023.csv',
    #     'csv_data/Annual_Donations_Made_2024.csv',
    ]

    # using data sourced from the AEC
    annual_donation_files.each do |file|
      # FileIngestor.annual_donor_ingest(file)
    end

  end

    annual_donation_files = [
  #     'csv_data/Annual_Donations_Made_2018.csv',
  #     'csv_data/Annual_Donations_Made_2019.csv',
  #     'csv_data/Annual_Donations_Made_2020.csv',
  #     'csv_data/Annual_Donations_Made_2021.csv',
  #     'csv_data/Annual_Donations_Made_2022.csv',
  #     'csv_data/Annual_Donations_Made_2023.csv',
  #     'csv_data/Annual_Donations_Made_2024.csv',
    ]

  #   federal_parliamentarians = [
  #     'csv_data/wiki_feds_current_mps_cleaned.csv',
  #     'csv_data/wiki_feds_current_senators_cleaned.csv',
  #     'csv_data/wiki_feds_ending_2019_cleaned.csv',
  #     'csv_data/wiki_feds_ending_2022_cleaned.csv',
  #     'csv_data/wiki_feds_senators_ending_2019_cleaned.csv',
  #     'csv_data/wiki_feds_senators_ending_2022_cleaned.csv'
  #   ]

  #   federal_ministries = [
  #     'csv_data/ministries_morrison.csv',
  #     'csv_data/ministries_turnbull.csv',
  #   ]

    # # using data sourced from the AEC
    # annual_donation_files.each do |file|
    #   FileIngestor.annual_donor_ingest(file)
    # end

  #   FileIngestor.referendum_donor_ingest('csv_data/Referendum_Donations_Made_2023.csv')

  #   # using data sourced from wikipedia
  #   federal_parliamentarians.each do |file|
  #     FileIngestor.federal_parliamentarians_upload(file)
  #   end

  #   # using data sourced from wikipedia
  #   federal_ministries.each do |file|
  #     FileIngestor.ministries_upload(file)
  #   end

  #   # From a file created and maintained by me, whenever noteworthy people or groups appear in the news
  #   FileIngestor.general_upload('csv_data/other_people_groups_positions.csv')

  #   # From a file created and maintained by me, linking groups to groups, whenever information comes to light
  #   FileIngestor.affiliations_upload('csv_data/affiliations.csv')

  #   # From a file created and maintained by me, whenever noteworthy money transfers appear in the news
  #   FileIngestor.transfers_upload('csv_data/other_transfers.csv')

  #   # Using data sourced from the AEC
  #   FileIngestor.election_donations_ingest('csv_data/Election_Donations_Made_to_2022.csv')

  #   # # ALP Senators, State and past members
  #   # Membership.find_or_create_by(group: labor_federal, member: kevin_rudd, start_date: Date.new(2006, 12, 4), end_date: Date.new(2010, 6, 24))
  #   # Membership.find_or_create_by(group: labor_federal, member: mark_latham, start_date: Date.new(2003, 12, 2), end_date: Date.new(2005, 1, 18))
  #   # Membership.find_or_create_by(group: labor_nsw, member: ian_macdonald, start_date: Date.new(1988, 3, 19), end_date: Date.new(2010, 6, 7))
  #   # Membership.find_or_create_by(group: labor_nsw, member: eddie_obeid, start_date: Date.new(1991, 5, 6), end_date: Date.new(2011, 5, 6))

  #   # Membership.find_or_create_by(group: one_nation, member: mark_latham, start_date: Date.new(2018, 11, 15), end_date: Date.new(2022, 6, 30))

  # end
end
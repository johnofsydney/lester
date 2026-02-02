namespace :lester do
  desc 'Augment'
  task augment: :environment do

    # NSW Parliamentarians from a list downloaded from
    # https://www.parliament.nsw.gov.au/members/downloadables/Pages/downloadable-lists.aspx
    # FileIngestor.nsw_parliamentarians_upload('csv_data/nsw_parliamentarians.csv')

    # From a file created and maintained by me, whenever noteworthy people or groups appear in the news
    # FileIngestor.general_upload(file: 'csv_data/other_people_groups_positions-2025-04-21.csv')

    # From a file created and maintained by me, linking groups to groups, whenever information comes to light
    # FileIngestor.affiliations_upload('csv_data/affiliations-2025-03-16.csv')

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
    #     'csv_data/Annual_Donations_Made_2024.csv',
      'csv_data/Annual_Donations_Made_2025.csv'
    ]

    # using data sourced from the AEC
    annual_donation_files.each do |file|
      FileIngestor.annual_donor_ingest(file)
    end

    # FileIngestor.election_donations_ingest('csv_data/Election_Donations_published_2025.csv')
  end

  #   federal_parliamentarians = [
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

  #   # Using data sourced from the AEC
  #   FileIngestor.election_donations_ingest('csv_data/Election_Donations_Made_to_2022.csv')


  #   FileIngestor.referendum_donor_ingest('csv_data/Referendum_Donations_Made_2023.csv')

  #   # using data sourced from wikipedia
  #   federal_parliamentarians.each do |file|
  #     FileIngestor.federal_parliamentarians_upload(file)
  #   end

  #   # using data sourced from wikipedia
  #   federal_ministries.each do |file|
  #     FileIngestor.ministries_upload(file)
  #   end

  #   # From a file created and maintained by me, whenever noteworthy money transfers appear in the news
  #   FileIngestor.transfers_upload('csv_data/other_transfers.csv')
end
# Imports one NSW council's declared councillor and (where directly elected) mayoral election
# results for a given election cycle (Councils::Nsw::Elections): records each declared-elected
# candidate as a Person with an undated Membership and a Position titled 'Councillor' or 'Mayor',
# links party affiliation where shown, and appends a raw, dated observation to
# Person#council_election_data for a future interpretation pass to derive real tenure dates from
# (see People::RecordCouncilElectionData -- NSWEC's declared date only tells us "elected in this
# cycle," not a councillor's true start, so no date is recorded on the Membership/Position itself).
# Fetches the council's results page first to discover the actual contest path(s) -- a single
# "councillor" page for councils elected at-large, or one "ward-x/councillor" page per ward for
# councils divided into wards (there is no shortcut: a ward council has no flat "councillor" page
# at all), plus a separate "mayoral" page for councils that directly elect their mayor (most NSW
# councils instead elect the mayor from among councillors, and simply have no such page).
class Councils::Nsw::ImportCouncilResultRowJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  STATE = :nsw
  LOCAL_COUNCILS_TAG_NAME = 'Australian Local Councils'.freeze

  def perform(council_name, council_slug, election_id = Councils::Nsw::Elections.latest[:id])
    election = Councils::Nsw::Elections.find(election_id)

    url = "https://pastvtr.elections.nsw.gov.au/#{election[:id]}/#{council_slug}/results"
    results_page = Councils::PageDownloader.call(url)
    raise "Failed to download NSW council results page: #{url}" if results_page.blank?

    contest_refs = Councils::Nsw::ResultsPageParser.call(results_page)
    return if contest_refs.blank? && Councils::Nsw::ResultsPageParser.no_contest_expected?(results_page) # council was under administration, or runs its own election -- nothing to record
    raise "No councillor contest found on NSW council results page: #{url}" if contest_refs.blank?

    contests = contest_refs.filter_map do |ref|
      url = "https://pastvtr.elections.nsw.gov.au/#{election[:id]}/#{council_slug}/#{ref[:path]}"
      fetch_contest(url, title: ref[:title])
    end
    return if contests.blank? # not yet declared in any contest -- nothing to record yet

    council = Groups::RecordGroup.call(council_name)
    council.add_to_tag(tag_name: LOCAL_COUNCILS_TAG_NAME)

    contests.each { |contest| record_contest(council:, council_slug:, contest:, election:) }
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Nsw::ImportCouncilResultRowJob(#{council_name}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: url, message: e.message)
    raise e
  end

  private

  def fetch_contest(url, title:)
    page = Councils::PageDownloader.call(url)
    raise "Failed to download NSW councillor results: #{url}" if page.blank?

    result = Councils::Nsw::CouncillorResultsParser.call(page)
    return nil if result.blank? # not yet declared -- nothing to record yet

    result.merge(url:, title:)
  end

  def record_contest(council:, council_slug:, contest:, election:)
    evidence = "NSW Electoral Commission #{election[:year]} LG election declared results (#{contest[:url]})"

    contest[:candidates].each do |candidate|
      record_candidate(council:, council_slug:, candidate:, declared_date: contest[:declared_date], evidence:, election:, source_url: contest[:url], title: contest[:title])
    end
  end

  def record_candidate(council:, council_slug:, candidate:, declared_date:, evidence:, election:, source_url:, title:)
    person = RecordCandidatePerson.call(name: candidate[:name], scope_group: council)

    Group::RecordRow.new(group: council, person:, title:, evidence:).call
    record_party_membership(person:, candidate:, evidence:)
    record_election_data(person:, council:, council_slug:, candidate:, declared_date:, election:, source_url:)
  end

  def record_election_data(person:, council:, council_slug:, candidate:, declared_date:, election:, source_url:)
    People::RecordCouncilElectionData.call(
      person:,
      observation: {
        state: STATE,
        council_name: council.name,
        council_slug:,
        cycle: election[:id],
        declared_date:,
        party: candidate[:party],
        source_url:
      }
    )
  end

  def record_party_membership(person:, candidate:, evidence:)
    party_group = Councils::PartyMapper.call(candidate[:party], state: STATE)
    return if party_group.nil?

    Group::RecordRow.new(group: party_group, person:, evidence:).call
  end
end

# Imports one NSW council's declared councillor election results: records each
# declared-elected candidate as a Person with a Membership (real start_date from the
# declaration date), links party affiliation where shown, and closes out anyone
# previously on the council who wasn't returned. Fetches the council's results page
# first to discover the actual councillor contest path(s) -- a single "councillor"
# page for councils elected at-large, or one "ward-x/councillor" page per ward for
# councils divided into wards (there is no shortcut: a ward council has no flat
# "councillor" page at all).
class Councils::Nsw::ImportCouncilResultRowJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  ELECTION_ID = 'LG2401'.freeze
  ELECTION_YEAR = 2024
  STATE = :nsw
  LOCAL_COUNCILS_TAG_NAME = 'Australian Local Councils'.freeze

  def perform(council_name, council_slug)
    url = "https://pastvtr.elections.nsw.gov.au/#{ELECTION_ID}/#{council_slug}/results"
    results_page = Councils::PageDownloader.call(url)
    raise "Failed to download NSW council results page: #{url}" if results_page.blank?

    councillor_paths = Councils::Nsw::ResultsPageParser.call(results_page)
    raise "No councillor contest found on NSW council results page: #{url}" if councillor_paths.blank?

    contests = councillor_paths.filter_map do |path|
      url = "https://pastvtr.elections.nsw.gov.au/#{ELECTION_ID}/#{council_slug}/#{path}"
      fetch_contest(url)
    end
    return if contests.blank? # not yet declared in any contest -- nothing to record yet

    council = Groups::RecordGroup.call(council_name)
    council.add_to_tag(tag_name: LOCAL_COUNCILS_TAG_NAME)

    recorded_people = contests.flat_map { |contest| record_contest(council:, contest:) }

    # Only close out departed members once every contest for this council has
    # declared -- if a ward hasn't declared yet, its sitting councillors are absent
    # from recorded_people too, and closing them out here would wrongly read as
    # "not returned" when we simply haven't checked their ward yet.
    # Wards can declare on different dates -- use the latest so a departed member's
    # end_date never precedes the declaration that actually confirmed they're out.
    close_departed_members(council:, recorded_people:, declared_date: contests.map { |c| c[:declared_date] }.max) if recorded_people.present? && contests.size == councillor_paths.size
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Nsw::ImportCouncilResultRowJob(#{council_name}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: url, message: e.message)
    raise e
  end

  private

  def fetch_contest(url)
    page = Councils::PageDownloader.call(url)
    raise "Failed to download NSW councillor results: #{url}" if page.blank?

    result = Councils::Nsw::CouncillorResultsParser.call(page)
    return nil if result.blank? # not yet declared -- nothing to record yet

    result.merge(url:)
  end

  def record_contest(council:, contest:)
    evidence = "NSW Electoral Commission #{ELECTION_YEAR} LG election declared results (#{contest[:url]})"

    contest[:candidates].filter_map do |candidate|
      record_candidate(council:, candidate:, declared_date: contest[:declared_date], evidence:)
    end
  end

  def record_candidate(council:, candidate:, declared_date:, evidence:)
    person = People::RecordPerson.call(candidate[:name])
    return nil if person.nil?

    Group::RecordRow.new(
      group: council, person:, title: 'Councillor', evidence:, start_date: declared_date
    ).call

    record_party_membership(person:, candidate:, declared_date:, evidence:)

    person
  end

  def record_party_membership(person:, candidate:, declared_date:, evidence:)
    party_group = Councils::PartyMapper.call(candidate[:party], state: STATE)
    return if party_group.nil?

    Group::RecordRow.new(group: party_group, person:, evidence:, start_date: declared_date).call
  end

  def close_departed_members(council:, recorded_people:, declared_date:)
    still_serving_ids = recorded_people.map(&:id)

    Membership.where(group: council, member_type: 'Person', end_date: nil)
              .where.not(member_id: still_serving_ids)
              .find_each do |membership|
      membership.update!(
        end_date: declared_date,
        evidence: [membership.evidence, "Not returned in the #{ELECTION_YEAR} NSW LG election"].compact.join(' / ')
      )
    end
  end
end

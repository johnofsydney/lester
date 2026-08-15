# Imports one NSW council's declared councillor election results for a given election cycle
# (Councils::Nsw::Elections): records each declared-elected candidate as a Person with a
# Membership (real start_date from the declaration date), links party affiliation where shown,
# and closes out anyone previously on the council who wasn't returned. Fetches the council's
# results page first to discover the actual councillor contest path(s) -- a single "councillor"
# page for councils elected at-large, or one "ward-x/councillor" page per ward for councils
# divided into wards (there is no shortcut: a ward council has no flat "councillor" page at all).
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

    councillor_paths = Councils::Nsw::ResultsPageParser.call(results_page)
    return if councillor_paths.blank? && Councils::Nsw::ResultsPageParser.no_contest_expected?(results_page) # council was under administration, or runs its own election -- nothing to record
    raise "No councillor contest found on NSW council results page: #{url}" if councillor_paths.blank?

    contests = councillor_paths.filter_map do |path|
      url = "https://pastvtr.elections.nsw.gov.au/#{election[:id]}/#{council_slug}/#{path}"
      fetch_contest(url)
    end
    return if contests.blank? # not yet declared in any contest -- nothing to record yet

    council = Groups::RecordGroup.call(council_name)
    council.add_to_tag(tag_name: LOCAL_COUNCILS_TAG_NAME)

    recorded_people = contests.flat_map { |contest| record_contest(council:, contest:, election:) }

    # Only close out departed members once every contest for this council has declared, AND only
    # for the latest known election cycle -- a backfilled (older) cycle must never close out
    # memberships that are still open because the person continued serving into a later cycle.
    # Wards can declare on different dates -- use the latest so a departed member's end_date never
    # precedes the declaration that actually confirmed they're out.
    close_departed_members(council:, recorded_people:, declared_date: contests.map { |c| c[:declared_date] }.max) if recorded_people.present? && contests.size == councillor_paths.size && Councils::Nsw::Elections.latest?(election[:id])
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

  def record_contest(council:, contest:, election:)
    evidence = "NSW Electoral Commission #{election[:year]} LG election declared results (#{contest[:url]})"

    contest[:candidates].filter_map do |candidate|
      record_candidate(council:, candidate:, declared_date: contest[:declared_date], evidence:, election:)
    end
  end

  def record_candidate(council:, candidate:, declared_date:, evidence:, election:)
    person = People::RecordPerson.call(candidate[:name])
    return nil if person.nil?

    Group::RecordRow.new(
      group: council, person:, title: 'Councillor', evidence:, start_date: declared_date,
      end_date: backfill_end_date(council:, person:, election:)
    ).call

    record_party_membership(person:, candidate:, declared_date:, evidence:)

    person
  end

  # A backfilled (non-latest) cycle must close out anyone who didn't continue serving into a
  # later cycle -- otherwise they'd be left with a dangling open membership forever, since only
  # the latest cycle's run performs close-outs. If the person already has an open membership on
  # this council, they continued serving (their real end_date, if any, belongs to a later cycle's
  # own close-out) -- leave it alone. Relies on the latest cycle already having been imported, so
  # "no open membership yet" reliably means they didn't continue.
  def backfill_end_date(council:, person:, election:)
    return nil if Councils::Nsw::Elections.latest?(election[:id])
    return nil if Membership.exists?(group: council, member: person, end_date: nil)

    Councils::Nsw::Elections.next(election[:id])[:election_date]
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
        evidence: [membership.evidence, 'Not returned in the NSW LG election'].compact.join(' / ')
      )
    end
  end
end

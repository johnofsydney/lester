# Imports one VIC council's declared councillor election results for a given election cycle
# (Councils::Vic::Elections): records each elected candidate as a Person with a Membership, and
# closes out anyone previously on the council who wasn't returned. Unlike NSW, VEC results pages
# don't show party affiliation, so no party membership is recorded here.
class Councils::Vic::ImportCouncilResultRowJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  LOCAL_COUNCILS_TAG_NAME = 'Australian Local Councils'.freeze

  def perform(council_name, council_slug, election_year = Councils::Vic::Elections.latest[:year])
    election = Councils::Vic::Elections.find(election_year)

    url = "https://www.vec.vic.gov.au/results/council-election-results/#{election[:year]}-council-election-results/#{council_slug}"
    page = Councils::PageDownloader.call(url)
    raise "Failed to download VIC council results: #{url}" if page.blank?

    result = Councils::Vic::CouncillorResultsParser.call(page)
    return if result.blank? # not yet declared -- nothing to record yet

    council = Groups::RecordGroup.call(council_name)
    council.add_to_tag(tag_name: LOCAL_COUNCILS_TAG_NAME)

    evidence = "Victorian Electoral Commission #{election[:year]} council election declared results (#{url})"
    declared_date = declared_date(election:, result:)
    recorded_people = result[:candidates].filter_map do |candidate|
      record_candidate(council:, candidate:, declared_date:, evidence:, election:)
    end

    # Guard against closing everyone out if the page parsed but yielded no usable candidates --
    # that's more likely a parsing problem than an empty council. Only the latest known election
    # cycle performs close-outs -- see backfill_end_date for why a backfilled cycle must not.
    close_departed_members(council:, recorded_people:, declared_date:) if recorded_people.present? && Councils::Vic::Elections.latest?(election[:year])
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Vic::ImportCouncilResultRowJob(#{council_name}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: url, message: e.message)
    raise e
  end

  private

  # The page's own "Last updated" date is only trustworthy for the live/latest cycle -- for any
  # backfilled cycle it reflects whenever VEC last regenerated the page, not the real historical
  # declaration date (confirmed live: every 2020 council page reports the same November 2024
  # "Last updated" stamp). Fall back to that cycle's known state-wide election_date instead.
  def declared_date(election:, result:)
    return result[:declared_date] if Councils::Vic::Elections.latest?(election[:year])

    election[:election_date]
  end

  def record_candidate(council:, candidate:, declared_date:, evidence:, election:)
    person = People::RecordPerson.call(candidate[:name])
    return nil if person.nil?

    Group::RecordRow.new(
      group: council, person:, title: 'Councillor', evidence:, start_date: declared_date,
      end_date: backfill_end_date(council:, person:, election:)
    ).call

    person
  end

  # A backfilled (non-latest) cycle must close out anyone who didn't continue serving into a
  # later cycle -- otherwise they'd be left with a dangling open membership forever, since only
  # the latest cycle's run performs close-outs. If the person already has an open membership on
  # this council, they continued serving (their real end_date, if any, belongs to a later cycle's
  # own close-out) -- leave it alone. Relies on the latest cycle already having been imported, so
  # "no open membership yet" reliably means they didn't continue.
  def backfill_end_date(council:, person:, election:)
    return nil if Councils::Vic::Elections.latest?(election[:year])
    return nil if Membership.exists?(group: council, member: person, end_date: nil)

    Councils::Vic::Elections.next(election[:year])[:election_date]
  end

  def close_departed_members(council:, recorded_people:, declared_date:)
    still_serving_ids = recorded_people.map(&:id)

    Membership.where(group: council, member_type: 'Person', end_date: nil)
              .where.not(member_id: still_serving_ids)
              .find_each do |membership|
      membership.update!(
        end_date: declared_date,
        evidence: [membership.evidence, 'Not returned in the VIC council election'].compact.join(' / ')
      )
    end
  end
end

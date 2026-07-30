# Imports one NSW council's declared councillor election results: records each
# declared-elected candidate as a Person with a Membership (real start_date from the
# declaration date), links party affiliation where shown, and closes out anyone
# previously on the council who wasn't returned.
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
    url = "https://pastvtr.elections.nsw.gov.au/#{ELECTION_ID}/#{council_slug}/councillor"
    page = Councils::PageDownloader.call(url)
    raise "Failed to download NSW councillor results: #{url}" if page.blank?

    result = Councils::Nsw::CouncillorResultsParser.call(page)
    return if result.blank? # not yet declared -- nothing to record yet

    council = Groups::RecordGroup.call(council_name)
    council.add_to_tag(tag_name: LOCAL_COUNCILS_TAG_NAME)

    evidence = "NSW Electoral Commission #{ELECTION_YEAR} LG election declared results (#{url})"
    recorded_people = result[:candidates].filter_map do |candidate|
      record_candidate(council:, candidate:, declared_date: result[:declared_date], evidence:)
    end

    # Guard against closing everyone out if the page parsed but yielded no usable
    # candidates (e.g. every name failed to resolve to a Person) -- that's more likely
    # a parsing problem than an empty council.
    close_departed_members(council:, recorded_people:, declared_date: result[:declared_date]) if recorded_people.present?
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Nsw::ImportCouncilResultRowJob(#{council_name}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: url, message: e.message)
    raise e
  end

  private

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

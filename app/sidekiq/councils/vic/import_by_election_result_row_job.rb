# Imports one VIC council by-election or countback result: records the elected candidate as a
# Person with an undated Councillor Membership, and appends a raw, dated observation to
# Person#council_election_data (see People::RecordCouncilElectionData). Dispatches to the parser
# matching `kind`: a by-election page shares Councils::Vic::CouncillorResultsParser's "Elected
# candidates" table with general-cycle pages, while a countback page is a structurally different
# plain key-value table (Councils::Vic::CountbackResultsParser) -- a countback recounts already-
# cast ballots to fill a casual vacancy, with no fresh vote to run a normal contest page for.
#
# `council_description` may include a ward/division suffix after a comma (e.g. "Maroondah City
# Council, Wonga Ward") -- only the council name before it is used to find/create the Group; VEC's
# ward subdivisions aren't modelled as their own Groups anywhere else in this pipeline either.
class Councils::Vic::ImportByElectionResultRowJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  STATE = :vic
  LOCAL_COUNCILS_TAG_NAME = 'Australian Local Councils'.freeze
  PARSER_BY_KIND = {
    'by_election' => Councils::Vic::CouncillorResultsParser,
    'countback' => Councils::Vic::CountbackResultsParser
  }.freeze
  EVIDENCE_LABEL_BY_KIND = {
    'by_election' => 'by-election',
    'countback' => 'countback'
  }.freeze

  def perform(slug, kind, council_description)
    url = "#{Councils::Vic::IngestByElectionResultsJob::TIMELINE_URL}/#{slug}"
    page = Councils::PageDownloader.call(url)
    raise "Failed to download VIC by-election/countback result page: #{url}" if page.blank?

    result = PARSER_BY_KIND.fetch(kind).call(page)
    return if result.blank? # not yet declared -- nothing to record yet

    council_name = council_description.split(',').first.strip
    council = Groups::RecordGroup.call(council_name)
    council.add_to_tag(tag_name: LOCAL_COUNCILS_TAG_NAME)

    evidence = "Victorian Electoral Commission #{EVIDENCE_LABEL_BY_KIND.fetch(kind)} declared results (#{url})"
    result[:candidates].each do |candidate|
      record_candidate(council:, candidate:, declared_date: result[:declared_date], evidence:, slug:, source_url: url)
    end
  rescue StandardError => e
    Rails.logger.error "Error processing Councils::Vic::ImportByElectionResultRowJob(#{slug}): #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: url, message: e.message)
    raise e
  end

  private

  def record_candidate(council:, candidate:, declared_date:, evidence:, slug:, source_url:)
    person = RecordCandidatePerson.call(name: candidate[:name], scope_group: council)

    Group::RecordRow.new(group: council, person:, title: 'Councillor', evidence:).call
    record_election_data(person:, council:, declared_date:, slug:, source_url:)
  end

  def record_election_data(person:, council:, declared_date:, slug:, source_url:)
    People::RecordCouncilElectionData.call(
      person:,
      observation: {
        state: STATE,
        council_name: council.name,
        council_slug: council.name.parameterize,
        cycle: slug,
        declared_date:,
        party: nil,
        source_url:
      }
    )
  end
end

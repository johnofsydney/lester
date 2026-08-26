# Top-level ingest job for a NSW state general election (LA only -- see
# docs/plans/0011-ingest-nsw-state-politicians-design.md for LC's still-undesigned status).
# Records all LA winners from the statewide "elected" page in one go, then discovers every
# electorate from the LA results index and fans out to
# NswStatePoliticians::ImportLaElectorateResultJob per electorate (for unsuccessful candidates),
# staggered to avoid hammering the Commission's site -- mirrors Councils::Nsw::IngestElectionResultsJob.
class NswStatePoliticians::IngestElectionResultsJob
  include Sidekiq::Job
  sidekiq_options queue: :low

  IMPORT_SPACING = 5.seconds

  def perform(event_id = NswStatePoliticians::Elections.latest[:id])
    @event_id = event_id
    record_winners
    fan_out_electorates
  rescue StandardError => e
    Rails.logger.error "Error processing NswStatePoliticians::IngestElectionResultsJob: #{e.message} - will retry"
    Rails.logger.error e.backtrace.join("\n")
    ApiLog.create(endpoint: elected_url, message: e.message)
    raise e
  end

  private

  attr_reader :event_id

  def record_winners
    winners_by_electorate.each_value do |winner|
      # electorate is normalised to the same slug format used for unsuccessful candidates below
      # (from the results index), so state_election_data's dedup key is consistent across both.
      NswStatePoliticians::RecordLaCandidate.call(event_id:, electorate: slugify(winner[:electorate]), name: winner[:name], party: winner[:party], elected: true, source_url: elected_url)
    end
  end

  # Keyed by electorate so `fan_out_electorates` can tell each per-electorate job which candidate
  # row on its fp_summary page is the already-recorded winner (fp_summary itself has no win/loss
  # column -- only the "elected" page does).
  def winners_by_electorate
    @winners_by_electorate ||= begin
      page = Councils::PageDownloader.call(elected_url)
      raise "Failed to download NSW LA elected page: #{elected_url}" if page.blank?

      winners = NswStatePoliticians::La::ElectedPageParser.call(page)
      raise "No winners found on NSW LA elected page: #{elected_url}" if winners.blank?

      winners.index_by { |winner| winner[:electorate] }
    end
  end

  def fan_out_electorates
    page = Councils::PageDownloader.call(results_index_url)
    raise "Failed to download NSW LA results index: #{results_index_url}" if page.blank?

    slugs = NswStatePoliticians::La::ResultsIndexParser.call(page)
    raise "No electorates found on NSW LA results index: #{results_index_url}" if slugs.blank?

    slugs.each_with_index do |slug, index|
      winner_name = winners_by_electorate.values.find { |w| slugify(w[:electorate]) == slug }&.dig(:name)
      NswStatePoliticians::ImportLaElectorateResultJob.perform_in(index * IMPORT_SPACING, event_id, slug, winner_name)
    end
  end

  # Best-effort match between the "elected" page's District display name (e.g. "Badgerys Creek")
  # and the results index's URL slug (e.g. "badgerys-creek") -- both are NSWEC-controlled and have
  # matched on every electorate checked live; if a future electorate ever doesn't match this way,
  # its winner simply gets recorded under a slightly different electorate value than its
  # unsuccessful-candidate rows would, which only affects state_election_data grouping, not
  # correctness of who gets ingested.
  def slugify(name)
    name.downcase.tr(' ', '-')
  end

  def elected_url
    "https://pastvtr.elections.nsw.gov.au/#{event_id}/LA/state/elected"
  end

  def results_index_url
    "https://pastvtr.elections.nsw.gov.au/#{event_id}/LA/results"
  end
end

class AusTender::IngestSingleContract
  def initialize(contract_id)
    @contract_id = contract_id
  end

  def url
    # There should not be a second page for a single contract
    "https://api.tenders.gov.au/ocds/findById/#{@contract_id}"
  end

  def perform
    response = AusTender::TenderDownloader.new.download(url)
    return unless response && response[:body] && response[:body]['releases']

    response[:body]['releases'].map { |raw_release| AusTender::Release.new(raw_release) }
                               .each { |release| AusTender::RecordIndividualTransaction.new(release).perform }
  end
end

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



    result = response[:body]['releases'].map do |raw_release|
      AusTender::Release.new(raw_release) # mapping everything into a nice PORO Release object
    end

    result = result.sort_by(&:amendment_index).map.with_index{|r, i| r.augment(previous_value: i.zero? ? 0.0 : result[i-1].value)}


    result.each { |release| AusTender::RecordIndividualTransaction.new(release).perform }
  end
end
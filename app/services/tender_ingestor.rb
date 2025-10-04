class ValidationError < StandardError; end

class TenderIngestor
  class << self
    def process_for_url(url:)
      Rails.logger.info "Processing Contracts for #{url}."

      contracts = new.fetch_contracts_for_url(url:)

      if contracts.blank?
        Rails.logger.warn "No contracts found for #{url}."
        return
      end

      contracts.each { |contract_id| IngestSingleContractJob.perform_async(contract_id) }
    end
  end

  def fetch_contracts_for_url(url: nil)
    # the url in this context will fetch all contracts for a given day (and page)
    # return an array of contract ids so we can process them individually
    response = AusTender::TenderDownloader.new.download(url)
    return unless response && response[:body] && response[:body]['releases']

    # If there is a next page, we need to fetch it and handle it asynchronously
    IngestContractsUrlJob.perform_async(response[:next_page]) if response[:next_page]

    # return array of unique contract ids
    response[:body]['releases'].map { |raw_release| raw_release['contracts'].first['id'] }.compact.uniq
  end
end






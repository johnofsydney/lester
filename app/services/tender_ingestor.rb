class ValidationError < StandardError; end
class ApiServerError < StandardError; end

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
    # the url in this context will fetch all contracts for a given url (corresponding to a day or subsequent page)
    # return an array of contract ids so we can process them individually
    response = AusTender::TenderDownloader.new.download(url)

    unless response[:success]
      raise ApiServerError.new(response.body) if response.status == 500
      raise StandardError.new("Failed to download data: #{response.body}, status code: #{response.status}")
    end



    return unless response && response[:body] && response[:body]['releases']

    # If there is a next page, we need to fetch it and handle it asynchronously.
    # By doing it quite a bit later we aim to reduce load on the server.
    IngestContractsUrlJob.perform_in(30.seconds, response[:next_page]) if response[:next_page]

    # return array of unique contract ids
    response[:body]['releases'].filter_map { |raw_release| raw_release['contracts'].first['id'] }.uniq
  end
end






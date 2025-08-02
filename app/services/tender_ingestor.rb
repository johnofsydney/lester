class TenderDownloader
  def download(url)
    conn = Faraday.new(url:)

    response = conn.get do |req|
      req.params['pretty'] = true
    end

    return unless response.success?

    body = JSON.parse(response.body)

    {
      body: body,
      next_page: next_page(body)
    }
  end

  def next_present?(body)
    body['links'] && body['links']['next'].present?
  end

    def next_page(body)
    return unless next_present?(body)

    body['links']['next']
  end
end

class TenderIngestor
  # def self.perform
  #   new.perform
  # end

  class << self
    # def process_for_date(date:)
    #   date = date.is_a?(String) ? Date.parse(date) : date
    #   beginning_of_day = date.beginning_of_day.iso8601
    #   end_of_day = date.end_of_day.iso8601

    #   url = "https://api.tenders.gov.au/ocds/findByDates/contractLastModified/#{beginning_of_day}/#{end_of_day}"

    #   process_for_url(url: url)
    # end

    def process_for_url(url:)
      instance = new
      contracts = instance.fetch_contracts_for_url(url: url)
      if contracts.blank?
        puts "No contracts found for #{url}."
        return
      end
      contracts.each do |contract|
        if contract[:tag] == 'contractAmendment'
          p "handle amendment"
          p contract[:contract_id]
          p contract[:contract_id]
          p "handle amendment"
          next
        end
        instance.record_contract(contract)
      end

      puts "\nContracts for #{url} processed."
    end
  end

  def record_contract(contract)
    purchaser = RecordGroup.call(contract[:purchaser_name])
    supplier = RecordGroup.call(contract[:supplier_name])
    contract_id = contract[:contract_id]
    contract_date = contract[:date]

    transfer = Transfer.find_or_create_by(
      giver: purchaser,
      taker: supplier,
      effective_date: Dates::FinancialYear.new(contract_date).last_day,
      transfer_type: 'Government Contract',
    )


    IndividualTransaction.create(
      transfer: transfer,
      amount: contract[:value].to_f,
      effective_date: contract[:date],
      transfer_type: 'Government Contract',
      evidence: "https://api.tenders.gov.au/ocds/findById/#{contract_id}",
      external_id: contract[:contract_id],
      # description: contract[:description]
    )

    transfer.amount += contract[:value].to_f
    transfer.save

    print '.'

  end

  def fetch_contracts_for_url(url: nil)
    response = TenderDownloader.new.download(url)
    return unless response


    body = response[:body]
    results = []

    if response && body && body['releases']
      results << body['releases'].map do |release|
        parsed_parties = release['parties'].map do |party|
          if party['roles'].include?('supplier')
            party_supplier = {
              name: party['name'],
              abn: party.dig('additionalIdentifiers', 0, 'id') || "",
              supplier: true
            }
          elsif party['roles'].include?('procuringEntity')
            procuringEntity = {
              name: party['name'],
              abn: party.dig('additionalIdentifiers', 0, 'id') || "",
              supplier: false
            }
          end
        end

        {
          ocid: release['ocid'],
          date: release['date'],
          value: release['contracts'].first['value']['amount'],
          contract_id: release['contracts'].first['id'],
          tag: release['tag'].first,
          supplier_name: parsed_parties.find { |party| party[:supplier] }[:name],
          supplier_abn: parsed_parties.find { |party| party[:supplier] }[:abn],
          purchaser_name: parsed_parties.find { |party| !party[:supplier] }[:name],
          purchaser_abn: parsed_parties.find { |party| !party[:supplier] }[:abn],
          description: release['contracts'].first['description']
        }
      end
    end

    if response && body && response[:next_page]
      # There are is a next page, so we need to fetch it. There may be more subsequent pages than can be handled with recursion
      IngestContractsUrlJob.perform_async(response[:next_page])
    end

    results.compact.flatten
  end

  def fetch_contract(contract_id)
    results = []
    url =  "https://api.tenders.gov.au/ocds/findById/#{contract_id}"

    response = download(url)

    body = response[:body]

    if response && body && body['releases']
      p "Processing contract: #{contract_id}"
      # p body['releases']

      results << body['releases'].map do |release|
        {
          ocid: release['ocid'],
          release_id: release['id'],
          date: release['date'],
          values: release['contracts'].map { |contract| contract['value']['amount'] },
          parties: mapped_parties(release),
          supplier: supplier(release),
          contract_id: release['contracts'].first['id'],
          awards_id: release['contracts'].first['awardID'],
          description: release['contracts'].first['description'],
        }
      end
    end

    results = results.compact.flatten
    first_result = results.first
    # binding.pry

    {
      contract_id: first_result[:contract_id],
      supplier: {
        name: first_result[:parties].find{ |party| party[:supplier] }[:name],
        abn: first_result[:parties].find{ |party| party[:supplier] }[:abn],
      },
      purchaser: {
        name: first_result[:parties].find{ |party| !party[:supplier] }[:name],
        abn: first_result[:parties].find{ |party| !party[:supplier] }[:abn],
      },
      description: first_result[:description],
      value: results.map{|result| result[:values] }.flatten.map(&:to_f).sum,
      details: results.map do |result|
        {
          release_id: result[:release_id],
          date: result[:date],
          values: result[:values],
          description: result[:description],
        }
      end
    }

    # results.compact.flatten.map do |result|
    #   {
    #     contract_id: result[:contract_id],
    #     awards_id: result[:awards_id],
    #     ocid: result[:ocid],
    #     date: result[:date],
    #     values: result[:values],
    #     parties: result[:parties],
    #     supplier_name: result[:parties].find{ |party| party[:supplier] == true }[:name],
    #     supplier_abn: result[:parties].find{ |party| party[:supplier] == true }[:abn],
    #     purchaser_name: result[:parties].find{ |party| party[:supplier] == false }[:name],
    #     purchaser_abn: result[:parties].find{ |party| party[:supplier] == false }[:abn],
    #   }
    # end
  end

  def mapped_parties(release)
    release['parties'].map do |party|
      {
        name: party['name'],
        abn: party.dig('additionalIdentifiers', 0, 'id') || "cant find additional identifier",
        supplier: party['name'] == supplier(release)
      }
    end
  end

  def supplier(release)
    raw_awards = release['awards']
    name = raw_awards.map { |award| award['suppliers'].map { |supplier| supplier['name'] } }.flatten.first
  end
end

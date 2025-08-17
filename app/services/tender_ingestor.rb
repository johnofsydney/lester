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

class RecordIndividualTransaction
  def initialize(release)
    # Use database records if they exist, or create them if they don't
    @purchaser = RecordGroup.call(release[:purchaser_name])
    @supplier = RecordGroup.call(release[:supplier_name], business_number:release[:supplier_abn])

    # These values come straight from the API response
    @contract_id = release[:contract_id]
    @release_date = release[:date]
    @release_id = release[:external_id]
    @tag = release[:tag]
    @description = release[:description]
    @effective_date = release[:date]
    @amends_release_id = release[:amends_release_id]

    @release = release
  end

  attr_reader :purchaser, :supplier, :contract_id, :release_date, :release_id, :tag, :release, :description, :effective_date, :amends_release_id

  def perform
    return if IndividualTransaction.exists?(external_id: release_id)

    IndividualTransaction.create(
      transfer: transfer,
      amount: effective_amount,
      effective_date: effective_date,
      transfer_type: 'Government Contract',
      evidence: "https://api.tenders.gov.au/ocds/findById/#{contract_id}",
      external_id: release_id,  # the uniqe identifier from the external system
      contract_id: contract_id, # the contract can include several amendments
      description: description
    )

    transfer.amount += release[:value].to_f
    transfer.save
    print '.'

    true
  end

  def effective_amount
    return @release[:value] unless amends_release_id.present?
    return @release[:value] if IndividualTransaction.where(contract_id:).empty?

    previous_value = IndividualTransaction.where(contract_id:).sum(:amount)
    (@release[:value].to_f - previous_value).round(2)
  end

  def transfer
    @transfer ||= Transfer.find_or_create_by(
      giver: purchaser,
      taker: supplier,
      effective_date: Dates::FinancialYear.new(release_date).last_day,
      transfer_type: 'Government Contract(s)',
      evidence: 'https://www.tenders.gov.au/cn/search',
    )
  end
end

class TenderIngestor
  class << self
    def process_for_url(url:)
      instance = new
      releases = instance.fetch_contracts_for_url(url: url)
      if releases.blank?
        Rails.logger.info "No contracts found for #{url}."
      else
        releases.each {|release| RecordIndividualTransaction.new(release).perform }

        Rails.logger.info "Contracts for #{url} processed."
      end
    end
  end

  def fetch_contracts_for_url(url: nil)
    # ingest all of the contracts for a given URL, return an array of hashes, where each element represents a release
    # a release is a new contract or an amendment to an existing contract and contains sufficient information to create the relevant database records
    response = TenderDownloader.new.download(url)
    return unless response && response[:body] && response[:body]['releases']


    body = response[:body]

    results = body['releases'].map do |raw_release|

      release = Release.new(raw_release)

      {
        ocid: release.ocid,
        date: release.date,
        value: release.value,
        contract_id: release.contract_id,
        external_id: release.external_id,
        award_id: release.award_id,
        tag: release.tag,
        supplier_name: release.supplier_name,
        supplier_abn: release.supplier_abn,
        purchaser_name: release.purchaser_name,
        purchaser_abn: release.purchaser_abn,
        description: release.description,
        amends_release_id: release.amends_release_id
      }

    end

    if response[:next_page]
      # There are is a next page, so we need to fetch it and handle it asynchronously
      IngestContractsUrlJob.perform_async(response[:next_page])
    end

    results.compact.flatten
  end
end

class Release
  def initialize(raw_release)
    @ocid = raw_release['ocid']
    @date = raw_release['date']
    @external_id = raw_release['id']

    @raw_release = raw_release
  end

  attr_reader :ocid, :date, :external_id, :raw_release

  def value
    raw_release['contracts'].first['value']['amount']
  end

  def contract_id
    raw_release['contracts'].first['id']
  end

  def award_id
    raw_release['awards'].first['id']
  end

  def tag
    raw_release['tag'].first
  end

  def supplier_name
    parsed_parties.find { |party| party[:supplier] }[:name]
  end

  def supplier_abn
    parsed_parties.find { |party| party[:supplier] }[:abn]
  end

  def purchaser_name
    parsed_parties.find { |party| !party[:supplier] }[:name]
  end

  def purchaser_abn
    parsed_parties.find { |party| !party[:supplier] }[:abn]
  end

  def description
    raw_release['contracts'].first['description']
  end

  def amends_release_id
    amendments = raw_release['contracts'].first.dig('amendments')

    amendments.present? ? amendments.first['amendsReleaseID'] : nil
  end

  def parsed_parties
      raw_release['parties'].map do |party|
        if party['roles'].include?('supplier')
          party_supplier = {
            name: party['name'],
            abn: party.dig('additionalIdentifiers', 0, 'id') || '',
            supplier: true
          }
        elsif party['roles'].include?('procuringEntity')
          procuringEntity = {
            name: party['name'],
            abn: party.dig('additionalIdentifiers', 0, 'id') || '',
            supplier: false
          }
        end
      end
  end

end


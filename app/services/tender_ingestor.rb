class ValidationError < StandardError; end

class TenderDownloader
  def download(url)
    # https://app.swaggerhub.com/apis/austender/ocds-api/1.1#/
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
    # These values come straight from the API response
    @contract_id = release.contract_id
    @release_date = release.date
    @release_id = release.external_id
    @tag = release.tag
    @description = release.description
    @effective_date = release.date
    @amends_release_id = release.amends_release_id

    @release = release
  end

  attr_reader :contract_id, :release_date, :release_id, :tag, :release, :description, :effective_date, :amends_release_id

  def perform
    return if IndividualTransaction.exists?(external_id: release_id)
    raise ValidationError unless valid?

    IndividualTransaction.create(
      transfer:,
      amount: effective_amount,
      effective_date:,
      transfer_type: 'Government Contract',
      evidence: "https://api.tenders.gov.au/ocds/findById/#{contract_id}",
      external_id: release_id, # the uniqe identifier from the external system
      contract_id:, # the contract can include several amendments
      description:
    )

    print '.' # rubocop:disable Rails/Output

    transfer.increment!(:amount, effective_amount.to_f) # rubocop:disable Rails/SkipsModelValidations

    true
  end

  def valid?
    [purchaser, supplier, contract_id, release_date, release_id, tag, description, effective_date].all?(&:present?)
  end

  def effective_amount
    return release.value if amends_release_id.blank?
    return release.value if IndividualTransaction.where(contract_id:).empty?

    previous_value = IndividualTransaction.find_by(external_id: release.amends_release_id)&.amount || 0.0
    (release.value.to_f - previous_value).round(2)
  end

  def transfer
    @transfer ||= Transfer.find_or_create_by(
      giver: purchaser,
      taker: supplier,
      effective_date: Dates::FinancialYear.new(release_date).last_day,
      transfer_type: 'Government Contract(s)',
      evidence: 'https://www.tenders.gov.au/cn/search'
    )
  end

  def purchaser
    @purchaser ||= RecordGroup.call(release.purchaser_name, business_number: release.purchaser_abn, mapper:)
  end

  def supplier
    @supplier ||= RecordGroup.call(release.supplier_name, business_number: release.supplier_abn, mapper:)
  end

  def mapper
    ::MapGroupNamesGeneral.new
  end
end

class TenderIngestor
  class << self
    def process_for_url(url:)
      Rails.logger.info "Processing Contracts for #{url}."

      contracts = new.fetch_contracts_for_url(url:)

      if contracts.blank?
        Rails.logger.warn "No contracts found for #{url}."
        return
      end

      contracts.each { |release| RecordIndividualTransaction.new(release).perform }
    end
  end

  def fetch_contracts_for_url(url: nil)
    # ingest all of the contracts for a given URL, return an array of Nice RELEASE Objects, where each element represents a release
    # a release is a new contract or an amendment to an existing contract and contains sufficient information to create the relevant database records
    response = TenderDownloader.new.download(url)
    return unless response && response[:body] && response[:body]['releases']

    # If there is a next page, we need to fetch it and handle it asynchronously
    IngestContractsUrlJob.perform_async(response[:next_page]) if response[:next_page]

    response[:body]['releases'].map do |raw_release|
      Release.new(raw_release) # mapping everything into a nice PORO Release object
    end
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
    contract['value']['amount']
  end

  def contract_id
    contract['id']
  end

  def award_id
    raw_release['awards'].first['id']
  end

  def tag
    raw_release['tag'].first
  end

  def supplier_name
    supplier['name']
  end

  def supplier_abn
    supplier.dig('additionalIdentifiers', 0, 'id')
  end

  def purchaser_name
    purchaser['name']
  end

  def purchaser_abn
    purchaser.dig('additionalIdentifiers', 0, 'id')
  end

  def description
    contract['description']
  end

  def amends_release_id
    amendments = raw_release['contracts'].first['amendments']

    amendments.present? ? amendments.first['amendsReleaseID'] : nil
  end

  private

  def parties = raw_release['parties']
  def supplier = parties.find { |party| party['roles'].include?('supplier')}
  def purchaser = parties.find { |party| party['roles'].include?('procuringEntity')}
  def contract = raw_release['contracts'].first
end


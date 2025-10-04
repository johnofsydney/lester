class ValidationError < StandardError; end

class AusTender::RecordIndividualTransaction
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
    # return release.value if amends_release_id.blank?
    # # return release.value if IndividualTransaction.where(contract_id:).empty?

    # previous_value = IndividualTransaction.find_by(external_id: release.amends_release_id)&.amount || 0.0
    # (release.value.to_f - previous_value).round(2)

    # the tricky maths bit, mostly done elsewhere
    release.value.to_f - release.previous_value.to_f
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
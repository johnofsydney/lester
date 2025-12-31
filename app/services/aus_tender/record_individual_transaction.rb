class ValidationError < StandardError; end

class AusTender::RecordIndividualTransaction
  def initialize(release)
    @release = release
  end

  attr_reader :release

  def perform
    return if IndividualTransaction.exists?(external_id: release.item_id)
    raise ValidationError unless valid?

    IndividualTransaction.create(
      transfer:,
      amount:,
      effective_date: release.effective_date,
      transfer_type: 'Government Contract',
      evidence: release.evidence,
      external_id: release.item_id, # the uniqe identifier from the external system (inc UUID)
      contract_id: release.contract_id, # the contract can include several amendments
      amendment_id: release.amendment_id,
      description: release.description
    )

    RefreshTransferAmountJob.perform_in(6.hours, transfer.id)
  end

  def amount
    @amount ||= release.amount
  end

  def effective_date
    @effective_date ||= release.effective_date
  end

  def valid?
    [purchaser, supplier, effective_date, amount].all?(&:present?)
  end

  def transfer
    @transfer ||= Transfer.find_or_create_by!(
      giver: purchaser,
      taker: supplier,
      effective_date: Dates::FinancialYear.new(effective_date).last_day,
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
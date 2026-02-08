class ValidationError < StandardError; end

class AusTender::RecordIndividualTransaction
  def self.call(release)
    new(release).call
  end

  def initialize(release)
    @release = release
  end

  attr_reader :release

  def call
    return if IndividualTransaction.exists?(external_id: release.item_id)
    raise ValidationError("Invalid transaction data: #{release.inspect}") unless valid?

    individual_transaction = IndividualTransaction.create(
      transfer:,
      amount:,
      effective_date: release.effective_date,
      transfer_type: 'Government Contract',
      evidence: release.evidence,
      external_id: release.item_id, # the uniqe identifier from the external system (inc UUID)
      contract_id: release.contract_id, # the contract can include several amendments
      amendment_id: release.amendment_id,
      description: release.description,
      category: release.category
    )

    # wait a moment to allow the lock prevention of running duplicates in quick succession
    RefreshSingleTransferAmountJob.perform_in(5.minutes, transfer.id)

    # Tag the taker with category after a delay to help avoid running duplicates in quick succession
    AusTender::CategorizeTakerJob.perform_in(10.minutes, individual_transaction.id)
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
class ValidationError < StandardError; end

class AuGrants::RecordIndividualGrant
  def self.call(release)
    new(release).call
  end

  def initialize(release)
    @release = release
  end

  attr_reader :release

  def call
    return if release.aggregate? || release.redacted_recipient?
    return if IndividualTransaction.exists?(external_id: release.ga_id)
    raise ValidationError.new("Invalid grant data: #{release.inspect}") unless valid?

    individual_transaction = IndividualTransaction.create( # rubocop:disable Lint/UselessAssignment
      giver: agency,
      taker: recipient,
      transfer:,
      amount: release.amount,
      effective_date: release.effective_date,
      transaction_type: 'government_grant',
      evidence: release.evidence,
      external_id: release.ga_id,
      fine_grained_transaction_category:,
      description: release.description,
      city: release.recipient_city,
      state: release.recipient_state,
      postcode: release.recipient_postcode
    )

    Transfers::RefreshSingleTransferAmountJob.perform_in(5.minutes, transfer.id)
  end

  def valid?
    [agency, recipient, release.effective_date, release.amount, transfer].all?(&:present?)
  end

  def transfer
    Transfer.find_or_create_by!(
      giver: agency,
      taker: recipient,
      effective_date: Dates::FinancialYear.new(release.effective_date).last_day,
      transfer_type: 'government_grants',
      evidence: 'https://www.grants.gov.au'
    )
  end

  def agency
    Groups::RecordGroup.call(release.agency_name, mapper:)
  end

  def recipient
    Groups::RecordGroup.call(release.recipient_name, business_number: release.recipient_abn, mapper:)
  end

  def fine_grained_transaction_category
    FineGrainedTransactionCategory.find_or_create_by!(name: release.category)
  end

  def mapper
    ::MapGroupNamesGeneral.new
  end
end

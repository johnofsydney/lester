class AusTender::CategorizeTaker
  def self.call(individual_transaction)
    new(individual_transaction).call
  end

  def initialize(individual_transaction)
    @individual_transaction = individual_transaction
  end

  attr_reader :individual_transaction

  def call
    return unless category.present? && taker.present? && taker.is_group?

    taker.add_category(category_name:)
  end

  def taker
    @taker ||= individual_transaction.transfer.taker
  end

  def category_name
    @category ||= MapTransactionCategories.new.call(individual_transaction.category)
  end
end

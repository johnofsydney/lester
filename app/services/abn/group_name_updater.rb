class Abn::GroupNameUpdater
  def self.call(group)
    new(group).call
  end

  def initialize(group)
    @group = group
  end

  def call
    return if group.business_number.blank?

    result = Abn::FetchBusinessNames.call(group.business_number)

    group.update(name: result[:main_name])

    group.trading_names.where(source: 'abn').destroy_all
    result[:trading_names].each do |trading_name|
      next if TradingName.normalize_value_for(:name, trading_name) == group.name

      group.trading_names.create_or_find_by!(name: trading_name) { |tn| tn.source = 'abn' }
    end
  rescue AbnDetailsSuppressed => e
    # Many details, including name, are suppressed for this ABN. Don't update the group, don't retry.
    Rails.logger.info("ABN details suppressed for group: #{group.id} with business number: #{group.business_number}")
    NewRelic::Agent.notice_error(e, custom_params: { group_id: group.id, business_number: group.business_number })
  rescue AbnNotFound => e
    # ABN not found. Don't update the group, don't retry.
    Rails.logger.info("ABN not found for group: #{group.id} with business number: #{group.business_number}")
    NewRelic::Agent.notice_error(e, custom_params: { group_id: group.id, business_number: group.business_number })
  end

  private

  attr_reader :group
end
class Abn::GroupNameUpdater
  def self.call(group)
    new(group).call
  end

  def initialize(group)
    @group = group
  end

  def call
    return unless group.business_number.present?

    result = Abn::FetchBusinessNames.call(group.business_number)

    group.update(name: result[:main_name])

    group.trading_names.destroy_all
    result[:trading_names].each do |trading_name|
      group.trading_names.create(name: trading_name)
    end
  end

  private

  attr_reader :group
end
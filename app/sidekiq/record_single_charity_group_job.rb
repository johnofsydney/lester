class RecordSingleCharityGroupJob
  include Sidekiq::Job

  sidekiq_options(
    queue: :low,
    lock: :until_executed,
    on_conflict: :log,
    retry: 3
  )

  def perform(group_name, business_number, category_id)
    group = RecordGroup.call(group_name, business_number:, mapper:)
    Membership.find_or_create_by(group_id: category_id, member: group)
  end

  def mapper
    MapGroupNamesGeneral.new
  end
end

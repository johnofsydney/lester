#  can DELETE after running

class Maintenance::DowncaseAllNamesJob
  include Sidekiq::Job
  sidekiq_options queue: :low, retry: 5

  def perform(id)
    group = Group.find(id)
    group.update!(name: group.name.downcase) if group.name.downcase != group.name
  end
end

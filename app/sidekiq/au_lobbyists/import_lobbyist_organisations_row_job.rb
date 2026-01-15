class AuLobbyists::ImportLobbyistOrganisationsRowJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  def perform(lobbyist_name, lobbyist_abn, start_date)
    lobbyist = RecordGroup.call(lobbyist_name, lobbyist_abn, start_date)
    return if lobbyist.nil? or lobbyist.id.nil?

    start_date = Date.parse(start_date) if start_date.present?
    lobbyists_category = Group.lobbyists_category
    evidence = 'https://lobbyists.ag.gov.au/register'

    # then add this lobbyist to the lobbyists category
    if (membership = Membership.find_by(member: lobbyist, group: lobbyists_category))
      membership.update(start_date:) if start_date.present? && membership.start_date.blank?
      membership.update(evidence:) if evidence.present? && membership.evidence.blank?
    else
      Membership.create!(member: lobbyist, group: lobbyists_category, start_date:, evidence:)
    end
  end
end
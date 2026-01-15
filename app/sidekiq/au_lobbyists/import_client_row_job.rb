class AuLobbyists::ImportClientRowJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  def perform(client_name, client_abn, start_date, lobbyist_name, lobbyist_abn)
    client = RecordGroup.call(client_name, business_number: client_abn)
    lobbyist = RecordGroup.call(lobbyist_name, business_number: lobbyist_abn)
    return if client.nil? || lobbyist.nil? || client.id.nil? || lobbyist.id.nil?

    start_date = Date.parse(start_date) if start_date.present?
    lobbyists_category = Group.lobbyists_category
    client_of_lobbyists_category = Group.client_of_lobbyists_category
    evidence = 'https://lobbyists.ag.gov.au/register'

    # membership of client with individual lobbyist
    if (membership = Membership.find_by(member: client, group: lobbyist))
      membership.update!(start_date:) if start_date.present? && membership.start_date.blank?
      membership.update!(evidence:) if evidence.present? && membership.evidence.blank?
    else
      Membership.create!(member: client, group: lobbyist, start_date:, evidence:)
    end

    # ensure both are added to categories
    # first - lobbyists category
    if (membership = Membership.find_by(member: lobbyist, group: lobbyists_category))
      membership.update!(start_date:) if start_date.present? && membership.start_date.blank?
      membership.update!(evidence:) if evidence.present? && membership.evidence.blank?
    else
      Membership.create!(member: lobbyist, group: lobbyists_category, start_date:, evidence:)
    end
    # second - client of lobbyists category
    if (membership = Membership.find_by(member: client, group: client_of_lobbyists_category))
      membership.update!(start_date:) if (start_date.present? && membership.start_date.blank?)
      membership.update!(evidence:) if (evidence.present? && membership.evidence.blank?)
    else
      Membership.create!(member: client, group: client_of_lobbyists_category, start_date:, evidence:)
    end
  end
end

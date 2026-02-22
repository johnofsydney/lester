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
    lobbyists_tag = Group.lobbyists_tag
    client_of_lobbyists_tag = Group.client_of_lobbyists_tag
    evidence = 'https://lobbyists.ag.gov.au/register'

    # For all of these Membership find or create, there could theoretically be a 2nd (or more) valid membership.
    # However in practice, for membership of lobbyist (and tags) we will assume that there is only one valid membership
    # IE no one ever ceases to be a lobbyist and then becomes a lobbyist again with a new membership record.
    # membership of client with individual lobbyist
    if (membership = Membership.find_by(member: client, group: lobbyist))
      membership.update!(start_date:) if start_date.present? && membership.start_date.blank?
      membership.update!(evidence:) if evidence.present? && membership.evidence.blank?
    else
      Membership.create!(member: client, group: lobbyist, start_date:, evidence:)
    end

    # ensure both are added to tags
    # first - lobbyists tag
    if (membership = Membership.find_by(member: lobbyist, group: lobbyists_tag))
      membership.update!(start_date:) if start_date.present? && membership.start_date.blank?
      membership.update!(evidence:) if evidence.present? && membership.evidence.blank?
    else
      Membership.create!(member: lobbyist, group: lobbyists_tag, start_date:, evidence:)
    end
    # second - client of lobbyists tag
    if (membership = Membership.find_by(member: client, group: client_of_lobbyists_tag))
      membership.update!(start_date:) if start_date.present? && membership.start_date.blank?
      membership.update!(evidence:) if evidence.present? && membership.evidence.blank?
    else
      Membership.create!(member: client, group: client_of_lobbyists_tag, start_date:, evidence:)
    end
  end
end

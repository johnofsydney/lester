class AuLobbyists::ImportLobbyistsPeopleRowJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  def perform(person_name, title, start_date, lobbyist_name, lobbyist_abn)
    person = RecordPerson.call(person_name)
    lobbyist = RecordGroup.call(lobbyist_name, business_number: lobbyist_abn)
    return if person.nil? || lobbyist.nil? || person.id.nil? || lobbyist.id.nil?

    start_date = Date.parse(start_date) if start_date.present?
    lobbyists_category = Group.lobbyists_category
    evidence = 'https://lobbyists.ag.gov.au/register'

    # membership of person with their employer
    if (membership = Membership.find_by(member: person, group: lobbyist))
      membership.update!(start_date:) if start_date.present? && membership.start_date.blank?
      membership.update!(evidence:) if evidence.present? && membership.evidence.blank?
    else
      membership = Membership.create!(member: person, group: lobbyist, start_date:, evidence:)
    end

    if membership.positions.find { |p| p.title == title }
      # do nothing
    else
      Position.create!(membership:, title:, start_date:)
    end

    # ensure lobbyist person is added to lobbyists category
    if (membership = Membership.find_by(member: person, group: lobbyists_category))
      membership.update!(start_date:) if start_date.present? && membership.start_date.blank?
      membership.update!(evidence:) if evidence.present? && membership.evidence.blank?
    else
      Membership.create!(member: person, group: lobbyists_category, start_date:, evidence:)
    end
  end
end

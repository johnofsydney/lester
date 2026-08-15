class AuLobbyists::ImportLobbyistsPeopleRowJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  def perform(person_name, title, start_date, lobbyist_name, lobbyist_abn)
    person = People::RecordPerson.call(person_name)
    lobbyist = Groups::RecordGroup.call(lobbyist_name, business_number: lobbyist_abn)
    return if person.nil? || lobbyist.nil? || person.id.nil? || lobbyist.id.nil?

    start_date = Date.parse(start_date) if start_date.present?
    lobbyists_tag = Group.lobbyists_tag
    evidence = 'https://lobbyists.ag.gov.au/register'

    # membership of person with their employer
    membership = upsert_membership(member: person, group: lobbyist, start_date:, evidence:)
    Position.create!(membership:, title:, start_date:) unless membership.positions.find { |p| p.title == title }

    # ensure lobbyist person is added to lobbyists tag
    upsert_membership(member: person, group: lobbyists_tag, start_date:, evidence:)
  end

  private

  def upsert_membership(member:, group:, start_date:, evidence:)
    membership = Membership.find_or_create_by!(member:, group:) do |m|
      m.start_date = start_date
      m.evidence = evidence
    end
    membership.update!(start_date:) if start_date.present? && membership.start_date.blank?
    membership.update!(evidence:) if evidence.present? && membership.evidence.blank?
    membership
  end
end

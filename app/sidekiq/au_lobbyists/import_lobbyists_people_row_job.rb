class AuLobbyists::ImportLobbyistsPeopleRowJob
  include Sidekiq::Job

  sidekiq_options(
    lock: :until_executed,
    on_conflict: :log,
    retry: 1
  )

  def perform(person_name, title, start_date, lobbyist_name, lobbyist_abn)
    # The AGD register has no native per-lobbyist ID, so we synthesise a stable one from the
    # raw row fields (not the cleaned-up name) so this job doesn't need to duplicate
    # People::RecordPerson's name-cleaning logic just to compute a lookup key.
    lobbyist_id = Digest::SHA256.hexdigest("#{person_name}|#{lobbyist_abn}")
    person = People::RecordPerson.call(person_name, lobbyist_id:)
    lobbyist = Groups::RecordGroup.call(lobbyist_name, business_number: lobbyist_abn)
    return if person.nil? || lobbyist.nil? || person.id.nil? || lobbyist.id.nil?

    start_date = Date.parse(start_date) if start_date.present?
    lobbyists_tag = Group.lobbyists_tag
    evidence = 'https://lobbyists.ag.gov.au/register'

    # membership of person with their employer
    membership = Membership.find_or_create_by!(member: person, group: lobbyist) do |m|
      m.start_date = start_date
      m.evidence = evidence
    end
    membership.update!(start_date:) if start_date.present? && membership.start_date.blank?
    membership.update!(evidence:) if evidence.present? && membership.evidence.blank?

    Position.create!(membership:, title:, start_date:) unless membership.positions.find { |p| p.title == title }

    # ensure lobbyist person is added to lobbyists tag
    tag_membership = Membership.find_or_create_by!(member: person, group: lobbyists_tag) do |m|
      m.start_date = start_date
      m.evidence = evidence
    end
    tag_membership.update!(start_date:) if start_date.present? && tag_membership.start_date.blank?
    tag_membership.update!(evidence:) if evidence.present? && tag_membership.evidence.blank?
  end
end

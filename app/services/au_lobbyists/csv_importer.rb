class AuLobbyists::CsvImporter
  def initialize; end

  def import_clients
    csv = CSV.read(clients_csv_path, headers: true)
    csv.each do |row|
      client_name = row["Client's Name"]&.strip
      client_abn = row["Client's ABN"]&.gsub(/\D/, '')
      start_date = Date.parse(row['Date Published']) if row['Date Published'].present?
      lobbyist_name = row['Parent Organisation']&.strip
      lobbyist_abn = row["Organisation's ABN"]&.gsub(/\D/, '')

      client = RecordGroup.call(client_name, business_number: client_abn, mapper:)
      lobbyist = RecordGroup.call(lobbyist_name, business_number: lobbyist_abn, mapper:)

      next if client.nil? || lobbyist.nil? || client.id.nil? || lobbyist.id.nil?

      # membership of client with individual lobbyist
      if (membership = Membership.find_by(member: client, group: lobbyist))
        membership.update(start_date:) if start_date.present? && membership.start_date.blank?
        membership.update(evidence:) if evidence.present? && membership.evidence.blank?
      else
        Membership.create!(member: client, group: lobbyist, start_date:, evidence:)
      end

      # ensure both are added to categories
      # first - lobbyists category
      if (membership = Membership.find_by(member: lobbyist, group: lobbyists_category))
        membership.update(start_date:) if start_date.present? && membership.start_date.blank?
        membership.update(evidence:) if evidence.present? && membership.evidence.blank?
      else
        Membership.create!(member: lobbyist, group: lobbyists_category, start_date:, evidence:)
      end
      # second - client of lobbyists category
      if (membership = Membership.find_by(member: client, group: client_of_lobbyists_category))
        membership.update(start_date:) if start_date.present? && membership.start_date.blank?
        membership.update(evidence:) if evidence.present? && membership.evidence.blank?
      else
        Membership.create!(member: client, group: client_of_lobbyists_category, start_date:, evidence:)
      end
    end
  end

  def import_lobbyist_people
    csv = CSV.read(lobbyist_people_csv_path, headers: true)
    csv.each do |row|
      person_name = row["Lobbyist's Name"]&.strip
      title = row['Job Title']&.strip
      start_date = Date.parse(row['Date Published']) if row['Date Published'].present?
      lobbyist_name = row['Parent Organisation']&.strip
      lobbyist_abn = row["Organisation's ABN"]&.gsub(/\D/, '')

      person = RecordPerson.call(person_name)
      lobbyist = RecordGroup.call(lobbyist_name, business_number: lobbyist_abn, mapper:)

      next if person.nil? || lobbyist.nil? || person.id.nil? || lobbyist.id.nil?

      # membership of person with their employer
      if (membership = Membership.find_by(member: person, group: lobbyist))
        membership.update(start_date:) if start_date.present? && membership.start_date.blank?
        membership.update(evidence:) if evidence.present? && membership.evidence.blank?
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
        membership.update(start_date:) if start_date.present? && membership.start_date.blank?
        membership.update(evidence:) if evidence.present? && membership.evidence.blank?
      else
        Membership.create!(member: person, group: lobbyists_category, start_date:, evidence:)
      end
    end
  end

  def import_lobbyist_organisations
    csv = CSV.read(lobbyist_organisations_csv_path, headers: true)
    csv.each do |row|
      lobbyist_name = row['Legal Name']&.strip
      row['Trading Name']&.strip
      lobbyist_abn = row['ABN']&.gsub(/\D/, '')
      start_date = Date.parse(row['Registered On']) if row['Registered On'].present?

      lobbyist = RecordGroup.call(lobbyist_name, business_number: lobbyist_abn, mapper:)

      # then add this lobbyist to the lobbyists category
      if (membership = Membership.find_by(member: lobbyist, group: lobbyists_category))
        membership.update(start_date:) if start_date.present? && membership.start_date.blank?
        membership.update(evidence:) if evidence.present? && membership.evidence.blank?
      else
        Membership.create!(member: lobbyist, group: lobbyists_category, start_date:, evidence:)
      end
    end
  end

  def clients_csv_path
    @clients_csv_path ||= Rails.root.join('tmp/clients.csv')
  end

  def lobbyist_people_csv_path
    @lobbyist_people_csv_path ||= Rails.root.join('tmp/lobbyists.csv')
  end

  def lobbyist_organisations_csv_path
    @lobbyist_organisations_csv_path ||= Rails.root.join('tmp/organisations.csv')
  end

  def mapper
    @mapper ||= MapGroupNamesAecDonations.new
  end

  def evidence
    'https://lobbyists.ag.gov.au/register'
  end

  def lobbyists_category
    @lobbyists_category ||= Group.find_by(name: 'Lobbyists', category: true)
  end

  def client_of_lobbyists_category
    @client_of_lobbyists_category ||= Group.find_by(name: 'Client of Lobbyists', category: true)
  end
end
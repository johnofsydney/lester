class FileIngestor

  def initialize(csv: nil, file: nil)
    raise unless csv || file

    @csv = csv || CSV.read(file, headers: true)
  end

  attr_reader :csv

  def general_upload
    # general upload does NOT record start and end dates for memberships
    csv.each do |row|
      group = Groups::RecordGroup.call(row['group'], mapper: MapGroupNamesBase.new)

      next if row['person'].blank?

      person = People::RecordPerson.call(row['person'])
      title = parse_title(row['title'])

      evidence = row['evidence'].strip if row['evidence'].present?
      start_date = parse_date(row['start_date']) if row['start_date'].present?
      end_date = parse_date(row['end_date']) if row['end_date'].present?

      # the membership may not exist, if so, we need to create it
      # There is no start date or end date added to the membership at this point
      membership = Membership.find_or_create_by(
        member_type: 'Person',
        member_id: person.id,
        group: group
      )

      # create position for each row, with unique dates and title
      position = Position.find_or_create_by(membership:, title:, start_date:, end_date:) if title || start_date || end_date

      membership.update!(evidence:) if evidence
      position.update!(evidence:) if evidence && position
    rescue => e
      Rails.logger.debug { "General Upload | Error: #{e} | row#{row.inspect}" }
    end
  end

  private

  def parse_title(title)
    return nil if title.blank?

    CapitalizeNames.capitalize(title.strip)
                   .gsub(/\bCEO\b/i, &:upcase)
  end

  def parse_date(date)
    return nil if date.blank?

    begin
      Date.parse(date)
    rescue Date::Error => e
      Rails.logger.debug { "Error parsing date: #{date} | Error: #{e.message}" }
      nil
    end
  end
end